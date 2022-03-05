const appConfig = require('./app.config.json');

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {},
  },
  plugins: [],
  safelist: appConfig.chatUsernameColors.map(color => `text-${color}`)
}
