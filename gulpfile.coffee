gulp = require 'gulp'
nodemon = require 'gulp-nodemon'


gulp.task('server', () ->
  nodemon({
    script: 'index.coffee'
    watch: __dirname
    ext: 'coffee'
    env:
      NODE_ENV: 'development'
    legacyWatch: false
  })
  .on('restart', () ->
    console.log 'RESTARTED NODE SERVER'
  )
)

gulp.task('default', ['d'])
gulp.task('d', ['server'])
