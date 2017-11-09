server {
    listen      %proxy_port%;
    server_name %domain_idn% %alias_idn%;
    error_log   /var/log/%web_system%/domains/%domain%.error.log error;

    index index.php;
 
    location / { 
        try_files $uri $uri/ /index.php?$args;
	}

    include /etc/nginx/fastcgi_params;
    include /etc/nginx/location_optmz_php.conf;

    location ~ \.php$ {
        if ($http_cookie ~ (comment_author_.*|wordpress_logged_in.*|wp-postpass_.*)) {
           set $no_cache 1;
        }

        fastcgi_index index.php;
        fastcgi_pass  unix:/var/run/vesta-php-fpm-%domain_idn%.sock;
        fastcgi_param SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        fastcgi_intercept_errors on;
        include fastcgi_params;

        fastcgi_cache_use_stale error timeout invalid_header http_500;
        fastcgi_cache_key $host$request_uri;
        fastcgi_cache site_diskcached;
        fastcgi_cache_valid 200 1m;
        fastcgi_cache_bypass $no_cache;
        fastcgi_no_cache $no_cache;
    }

    include %home%/%user%/web/%domain%/private/*.conf;
    include %home%/%user%/conf/web/nginx.%domain%.conf*;
}
