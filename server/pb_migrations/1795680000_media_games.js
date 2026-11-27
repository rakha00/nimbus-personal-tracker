/// <reference path="../pb_data/types.d.ts" />

// Games join the media log, with wishlist / progress / done like series and books.
migrate((app) => {
  const c = app.findCollectionByNameOrId("media_items");
  c.fields.getByName("type").values = ["film", "series", "anime", "book", "game"];
  app.save(c);
}, (app) => {
  const c = app.findCollectionByNameOrId("media_items");
  c.fields.getByName("type").values = ["film", "series", "anime", "book"];
  app.save(c);
});
