/// <reference path="../pb_data/types.d.ts" />

// Series and anime join films and books; series, anime and books can be "in progress".
migrate((app) => {
  const c = app.findCollectionByNameOrId("media_items");
  c.fields.getByName("type").values = ["film", "series", "anime", "book"];
  c.fields.getByName("status").values = ["wishlist", "progress", "done"];
  app.save(c);
}, (app) => {
  const c = app.findCollectionByNameOrId("media_items");
  c.fields.getByName("type").values = ["film", "book"];
  c.fields.getByName("status").values = ["wishlist", "done"];
  app.save(c);
});
