#!/usr/bin/env node

/**
 * MCP Server: Ticket Operations
 *
 * Provides tools for interacting with ticketing systems:
 * - list_tickets: List open tickets/issues
 * - get_ticket: Get ticket details
 * - create_ticket: Create a new ticket
 * - update_ticket: Update ticket status/assignee
 *
 * Supports: GitLab Issues, Jira, local Roadmap files.
 * Configuration is passed via environment variables.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js'
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js'
import {
  CallToolRequestSchema,
  ListToolsRequestSchema
} from '@modelcontextprotocol/sdk/types.js'
import { execSync } from 'child_process'
import { readFileSync, writeFileSync, existsSync } from 'fs'

const server = new Server(
  { name: 'ticket-ops', version: '1.0.0' },
  { capabilities: { tools: {} } }
)

// Detect provider from environment
const PROVIDER = process.env.TICKET_PROVIDER || 'none'

// --- GitLab helpers ---
function gitlabApi(path, method = 'GET', body = null) {
  const host = process.env.GITLAB_HOST || 'gitlab.com'
  const project = encodeURIComponent(process.env.GITLAB_PROJECT || '')
  const url = `https://${host}/api/v4/projects/${project}${path}`
  const cmd = body
    ? `glab api -X ${method} --input - "${url}" <<'EOF'\n${JSON.stringify(body)}\nEOF`
    : `glab api -X ${method} "${url}"`
  return JSON.parse(execSync(cmd, { encoding: 'utf-8' }))
}

function listGitlabTickets() {
  return gitlabApi('/issues?state=opened&per_page=20')
    .map(i => ({ id: i.iid, title: i.title, state: i.state, labels: i.labels, url: i.web_url }))
}

function getGitlabTicket(id) {
  const i = gitlabApi(`/issues/${id}`)
  return { id: i.iid, title: i.title, description: i.description, state: i.state, labels: i.labels, url: i.web_url }
}

// --- Jira helpers ---
function jiraApi(path, method = 'GET', body = null) {
  const url = `${process.env.JIRA_URL}/rest/api/3${path}`
  const auth = Buffer.from(`${process.env.JIRA_EMAIL}:${process.env.JIRA_API_TOKEN}`).toString('base64')
  const headers = [`Authorization: Basic ${auth}`, 'Content-Type: application/json']
  const headerArgs = headers.map(h => `-H "${h}"`).join(' ')
  const cmd = body
    ? `curl -s -X ${method} ${headerArgs} -d '${JSON.stringify(body)}' "${url}"`
    : `curl -s -X ${method} ${headerArgs} "${url}"`
  return JSON.parse(execSync(cmd, { encoding: 'utf-8' }))
}

function listJiraTickets() {
  const project = process.env.JIRA_PROJECT || ''
  const data = jiraApi(`/search?jql=project=${project} AND status!=Done&maxResults=20`)
  return (data.issues || []).map(i => ({
    id: i.key, title: i.fields.summary, state: i.fields.status.name, url: `${process.env.JIRA_URL}/browse/${i.key}`
  }))
}

function getJiraTicket(id) {
  const i = jiraApi(`/issue/${id}`)
  return {
    id: i.key, title: i.fields.summary,
    description: i.fields.description?.content?.map(c => c.content?.map(t => t.text).join('')).join('\n') || '',
    state: i.fields.status.name, url: `${process.env.JIRA_URL}/browse/${i.key}`
  }
}

// --- Roadmap helpers ---
function parseRoadmap() {
  const file = process.env.ROADMAP_FILE || 'ROADMAP.md'
  if (!existsSync(file)) return []
  const content = readFileSync(file, 'utf-8')
  const tickets = []
  let id = 0
  for (const line of content.split('\n')) {
    const match = line.match(/^[-*]\s+\[([x ])\]\s+(.+)$/i)
    if (match) {
      id++
      tickets.push({ id: String(id), title: match[2].trim(), state: match[1] === 'x' ? 'done' : 'open' })
    }
  }
  return tickets
}

function listRoadmapTickets() {
  return parseRoadmap().filter(t => t.state === 'open')
}

function getRoadmapTicket(id) {
  return parseRoadmap().find(t => t.id === id) || { error: 'Not found' }
}

// --- Tool dispatch ---
const tools = [
  {
    name: 'list_tickets',
    description: 'List open tickets from the configured ticketing provider',
    inputSchema: { type: 'object', properties: {} }
  },
  {
    name: 'get_ticket',
    description: 'Get details of a specific ticket by ID',
    inputSchema: { type: 'object', properties: { id: { type: 'string', description: 'Ticket ID' } }, required: ['id'] }
  }
]

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }))

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params

  try {
    let result
    switch (name) {
      case 'list_tickets':
        result = PROVIDER === 'gitlab' ? listGitlabTickets()
          : PROVIDER === 'jira' ? listJiraTickets()
          : PROVIDER === 'roadmap' ? listRoadmapTickets()
          : { error: 'No ticketing provider configured' }
        break
      case 'get_ticket':
        result = PROVIDER === 'gitlab' ? getGitlabTicket(args.id)
          : PROVIDER === 'jira' ? getJiraTicket(args.id)
          : PROVIDER === 'roadmap' ? getRoadmapTicket(args.id)
          : { error: 'No ticketing provider configured' }
        break
      default:
        result = { error: `Unknown tool: ${name}` }
    }
    return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] }
  } catch (err) {
    return { content: [{ type: 'text', text: `Error: ${err.message}` }], isError: true }
  }
})

const transport = new StdioServerTransport()
await server.connect(transport)
