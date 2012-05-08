##########################################################################
# Require
##########################################################################

# Questo require automatizza il processo di bundle in produzione,
# cioè capistrano è così furbo che dopo aver fatto il deploy del codice
# e dell'app già automaticamente esegue i suoi bundle --deployment 
# --without test development con tutti i cache e le ottimizzazioni
# possibili immaginabili.
# Posiziona vendor in shared/
require "bundler/capistrano"

# Per Rails 3.1 e' possibile precompilare gli assets in maniera molto
# potente; vengono cachati e mantenuti in shared/ con la seguente riga
load "deploy/assets"

##########################################################################
# Application
##########################################################################

# Il nome dell'applicazione
set :application, "refinery2test"

# Directory dove verrà creato l'albero delle revisioni sul server
set :deploy_to, "/home/f5lab_com/test1" 

##########################################################################
# Configurazione
##########################################################################

# Sul server non usare sudo (non è mai necessario infatti se
# si deploya un'app con bundle --deployment e lo sviluppatore
# è confinato dentro la root dell'applicazione - :deploy_to)
set :use_sudo, false

# Teniamo solo 10 release
set :keep_releases, 10

##########################################################################
# Repository svn
##########################################################################

#set :scm, :subversion
#set :repository,  "https://svn.rhx.it/svn/<project>/trunk"

# Username sull'SVN
# CONSIGLIATO salvare la password di subversion
#set :svn_username, ""

##########################################################################
# Repository git
##########################################################################
      
default_run_options[:pty] = true  # Must be set for the password prompt from git to work      

set :scm, :git
set :branch, "master"
set :repository, "git@github.com:matteofuzz/refinery2test.git"   

ssh_options[:forward_agent] = true

##########################################################################
# Server in produzione
##########################################################################

# Username SSH sul server
# CONSIGLIATO copiare la chiave pubblica in authorized_keys
set :user, "mfolin"

# Posizione dei server
role :web, "ruby.rhx.it"
role :app, "ruby.rhx.it"
role :db,  "ruby.rhx.it", :primary => true # Dove gira il DB (es MySQL)

##########################################################################
# Task personalizzati
##########################################################################

# Dopo aver copiato il progetto sul server di produzione
# (deploy:update_code) si possono eseguire ricette custom
# È anche possibile intervenire a metà dell'esecuzione
# delle varie ricette di capistrano
#after "deploy:update_code", :link_shared
after "deploy:update_code", :do_migrate         
after "deploy", :restart
after "deploy", 'deploy:cleanup'

# Crea collegamenti
desc "Link shared"
task :link_shared do
  run "ln -nfs #{shared_path}/spree #{release_path}/public/spree"
end

# Migrate DB
desc "migrate DB" 
task :do_migrate do
  run "cd #{release_path} && /var/lib/gems/1.9.1/bin/bundle exec rake RAILS_ENV=production db:migrate"
end

##########################################################################
# Passenger
##########################################################################

# Il task che fa refresh dell'app
desc "Restart Passenger" 
task :restart do
  run "cd #{current_path} && touch tmp/restart.txt" 
end
