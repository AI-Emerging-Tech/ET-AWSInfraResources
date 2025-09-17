server {

    listen ${LISTEN_PORT};
 
    location /static/static {

        alias /vol/static;

    }

    location /static/media {

        alias /vol/media;

    }
 
    location / {

        include                 gunicorn_headers;

        proxy_redirect          off;

        proxy_pass              http://${APP_HOST}:${APP_PORT};

        client_max_body_size    10M;

    }
    location /upload {

        include                 gunicorn_headers;

        proxy_redirect          off;
        # good defaults for ASGI/upgrade (harmless if unused)
    proxy_http_version 1.1;
    proxy_set_header Connection        "";

        proxy_pass              http://${APP_HOST}:12052;

        client_max_body_size    200M;
         # stream the request body instead of buffering to disk
    proxy_request_buffering off;

    # longer timeouts for OCR
    proxy_connect_timeout   60s;
    proxy_send_timeout      600s;
    proxy_read_timeout      600s;

    }
    

   

    

    

    

}
 

