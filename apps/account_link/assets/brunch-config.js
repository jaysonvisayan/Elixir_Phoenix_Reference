exports.config = {
    // See http://brunch.io/#documentation for docs.
    files: {
        javascripts: {
            joinTo: {
                "js/app.js": [
                    // "vendor/semantic/js/jquery.min.js",
                    // "vendor/semantic/js/semantic.min.js",
                    // "vendor/semantic/js/datatable.min.js",
                    // "vendor/semantic/js/calendar.min.js",
                    // "vendor/semantic/js/app.js",
                    // "vendor/semantic/js/alertify.min.js",
                    "node_modules/**/*",
                    "vendor/semantic/dist/**",
                    "vendor/js/**",
                    "js/**"
                    // "js/socket.js",
                    // "js/app.js"
                ]
            },
            order: {
                before: [
                    "vendor/js/jquery.min.js",
                    "vendor/semantic/dist/semantic.js",
                    "vendor/js/datatables/datatable.min.js",
                    "vendor/js/jquery-ui.min.js",
                    "vendor/js/calendar.min.js",
                    "vendor/js/sweetalert2.min.js",
                    "vendor/js/alertify.min.js"
                    // "js/socket.js",
                    // "js/app.js"
                ]
            }
        },
        stylesheets: {
            joinTo: {
                "css/app.css": [
                    'vendor/semantic/dist/**',
                    "vendor/css/**",
                    "css/**",
                ],
            },
        },
        templates: {
            joinTo: "js/app.js"
        }
    },

    conventions: {
        // This option sets where we should place non-css and non-js assets in.
        // By default, we set this to "/assets/static". Files in this directory
        // will be copied to `paths.public`, which is "priv/static" by default.
        assets: /^(static)/
    },

    // Phoenix paths configuration
    paths: {
        // Dependencies and current project directories to watch
        watched: ["static", "css", "js", "vendor"],
        // Where to compile files to
        public: "../priv/static"
    },

    // Configure your plugins
    plugins: {
        babel: {
            // Do not use ES6 compiler in vendor code
            ignore: [/vendor/]
        }
    },

    modules: {
        autoRequire: {
            "js/app.js": ["js/app"]
        }
    },

    npm: {
        enabled: true
    }
};