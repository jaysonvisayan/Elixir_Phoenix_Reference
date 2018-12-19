# Translation steps

1. Convert all translated strings to `<%= gettext "value" %>`
2. Extract the keywords to be translated `mix gettext.extract`
3. Migrate the keywords per language `mix gettext.merge priv/gettext --locale zh`
4. Go inside the `priv/getttext` folder and edit the .po files
5. Use Google translate to manually translate the values
