# frozen_string_literal: true

RSpec.shared_examples 'modulorails files' do |_combination|
  describe 'Modulorails setup' do
    it 'Gemfile contains modulorails gem' do
      expect(File.join(project_root, 'Gemfile')).to contain_gem('modulorails')
    end

    it 'has modulorails initializer or .modulorails.yml' do
      initializer = File.exist?(File.join(project_root, 'config/initializers/modulorails.rb'))
      config_file = File.exist?(File.join(project_root, '.modulorails.yml'))
      expect(initializer || config_file).to be true
    end
  end
end
