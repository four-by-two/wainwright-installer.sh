# wainwright-installer.sh
installer without docker for ubuntu &amp; debian -- for: https://github.com/four-by-two/casinodog-dev && https://github.com/casinodog-api-client

- installs nginx 
- sets it up 
- install php8.1 
- install redis-server with binding to localhost
- gets latest laravel from official repo, install plugins in the .wainwright folder and adds composer.json from root,
- links domain to `{working_dir}/casinodog/.`
- creates strong dh ssl 
- copies the cert.crt and privatekey in this folder to `/etc/nginx/ssl/{yourdomain.conf}`. 
- links symbolic to {yourdomain.conf} in this folder (it is created automatically from boilerplate, just so you are aware the location of nginx config is in this folder afterwards for domain)

## steps (important):
- **!** make sure to enter your link as `APP_URL` in `.env.casinodog` before you do anything, as it's used for nginx setup etc.
- **do not touch `nginx_boilerplate.conf` && `composer_template.json` - it will copy and symbolic link in working directory a new nginx config file with name of your domain: `${APP_URL}.conf`**
- you can link wainwright git repositories within `.env.casinodog` or try use default setting as is
- place cert.crt & private.key for your domain within the working folder of this script BEFORE executing script  (you can use certbot)
- execute `sudo chmod a+x`, followed by `./installer.sh`

## after install
- `cd casinodog`
- check if the `.wainwright` folder is populated with plugin folders: `ls .wainwright`
- check if composer copied properly and is including the 'wainwright/*' packages
- if all is fine, execute `composer update --no-cache --no-ansi --ignore-platform-reqs`
- restart webserver & php: `service nginx restart && service php8.1-fpm restart`
- finish off with `chown -R www-data:www-data .`

## need to reinstall?
Just copy the `installer.sh` and name it `reinstaller.sh` and just remove within script:
 - the nginx install block
 - the php block
 - the redis block at bottom

Delete the "casindog" directory (the application directory) or else just move the reinstaller.sh into other directory and start from scratch.

It's not science and all is very raw as not being able to have a stable remote git repository myself, so just make sure to find updated wainwright plugins just by searching "wainwright" on github & gitlab global search.
