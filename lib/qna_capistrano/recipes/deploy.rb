Capistrano::Configuration.instance.load do
  set :shared_children, %w(system log pids config)

  namespace :deploy do
    desc "|capistrano-recipes| Deploy it, github-style."
    task :default, :roles => :app, :except => { :no_release => false } do
      update
      restart
    end

    desc "|capistrano-recipes| Destroys everything"
    task :seppuku, :roles => :app, :except => { :no_release => false } do
      run "rm -rf #{current_path}; rm -rf #{shared_path}"
    end

    desc "|capistrano-recipes| Create shared dirs"
    task :setup_dirs, :roles => :app, :except => { :no_release => false } do
      commands = shared_dirs.map do |path|
        "mkdir -p #{shared_path}/#{path}"
      end
      run commands.join(" && ")
    end

    desc "|capistrano-recipes| Uploads your local config.yml to the server"
    task :configure, :roles => :app, :except => { :no_release => false } do
      generate_config('config/config.yml', "#{shared_path}/config/config.yml")
    end

    desc "|capistrano-recipes| Setup a GitHub-style deployment."
    task :setup, :roles => :app, :except => { :no_release => false } do
      setup_dirs
      t = Time.new.strftime('%s')
      run "git clone #{repository} #{deploy_to}/releases/#{t}"
      run "rm -f #{current_path}"
      run "ln -sf #{deploy_to}/releases/#{t} #{current_path}"
    end

    desc "|capistrano-recipes| Update the deployed code."
    task :update_code, :roles => :app, :except => { :no_release => false } do
      run "cd #{current_path}; git fetch origin; git reset --hard #{branch}"
    end

    desc "|capistrano-recipes| Remote run for rake db:seed"
    task :migrate, :roles => :app, :except => { :no_release => false } do
      run "cd #{current_path}; bundle exec rake RAILS_ENV=#{rails_env} db:seed"
    end

    desc "|capistrano-recipes| [Obsolete] Nothing to cleanup when using reset --hard on git"
    task :cleanup, :roles => :app, :except => { :no_release => false } do
      #nothing to cleanup, we're not working with 'releases'
      puts "Nothing to cleanup, yay!"
    end
  end
end
