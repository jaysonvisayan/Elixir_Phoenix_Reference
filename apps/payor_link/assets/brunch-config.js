exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: {
        "js/app.js": [
          'node_modules/**/*',
          'vendor/semantic/dist/**',
          'vendor/js/**',
          'js/behaviors/**',
          'js/components/**',
          'js/**',
        ]
      },

      // To use a separate vendor.js bundle, specify two files path
      // https://github.com/brunch/brunch/blob/master/docs/config.md#files
      // joinTo: {
      //  "js/app.js": /^(js|node_modules)/,
      //  "js/vendor.js": /^(vendor\/semantic\/dist)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      order: {
        before: [
          "vendor/js/jquery-3.2.1.min.js",
          "vendor/semantic/dist/semantic.js",
          "vendor/js/datatables/datatable.min.js",
          // "vendor/js/datatables/datatable.semanticui.min.js",
          // "vendor/js/datatables/dataTables.responsive.min.js",
          // "vendor/js/datatables/responsive.semanticui.min.js",
          "vendor/js/calendar.min.js",
          "vendor/js/alertify.min.js",
          "vendor/js/sweetalert2.min.js",
          "vendor/js/jquery.nicescroll.min.js",
          "vendor/js/jquery-ui.min.js"
        ]
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": [
          'vendor/semantic/dist/**',
          'vendor/css/**',
          'css/components/**',
          'css/utils/**',
          'css/app.scss'
        ],
        "css/main.css": [
          'css/main.scss',
          'vendor/css/**'
        ]
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/assets/static". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: [
      'static/**',
      'vendor/semantic/dist/themes/default/assets/**',
      'vendor/semantic/dist/themes/github/assets/**',
      'vendor/semantic/dist/themes/basic/assets/**',
      'vendor/semantic/dist/themes/material/assets/**',
    ],
    ignored: [
      /^(vendor\/semantic\/tasks)/,
      /^(vendor\/semantic\/src)/,
      /^(vendor\/semantic\/semantic.json)/,
      /^(vendor\/semantic\/gulpfile.js)/
    ]
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
    },
    sass: {
      options: {
        includePaths: [
          'node_modules'
        ]
      }
    },
    vue: {
      extractCSS: true,
      out: '../priv/static/css/components.css'
    },
    glob: {
      appDir: 'assets/js',
      stripExt: true,
      stripAppDir: true
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    whitelist: ["phoenix", "phoenix_html", "vue"]
  }
};
