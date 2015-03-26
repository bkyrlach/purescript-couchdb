module.exports = function(grunt) {
    "use strict";

    grunt.initConfig({
            srcFiles: [
                "bower_components/**/src/**/*.purs",
                "libs/**/src/**/*.purs",
                "src/**/*.purs"
            ],
            psc: {
                all: {
                    src: ["<%=srcFiles%>"],
                    dest: "bin/couchdb.js"
                }
            },
            dotPsci: ["<%=srcFiles%>"]
    });

    grunt.loadNpmTasks("grunt-purescript");
    grunt.registerTask("default", ["psc:all", "dotPsci"]);
};
