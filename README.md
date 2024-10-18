# Moduloproject

[Moduloproject](https://github.com/moduloTech/moduloproject) is an open-source project.

There are two components:

- a shell script
    - It spawn a Docker container running the last ruby image.
    - In this container, the last version of Rails is installed.
    - A new Rails project is generated running with a PostgreSQL database and using the Rails template.
- a Rails template
    - It adds and configures the gem [Modulorails](https://github.com/moduloTech/modulorails).
    - It setup the git repository.

## Installation and update

```bash
cd /usr/local/bin
sudo curl -o moduloproject https://raw.githubusercontent.com/moduloTech/moduloproject/master/moduloproject
sudo chmod +x moduloproject
```

## Usage

```bash
mkdir superproject
cd superproject
moduloproject # Or `moduloproject -m importmap -i mri -v latest`; Use `moduloproject -h` to see all options
docker compose up -d --build
```
