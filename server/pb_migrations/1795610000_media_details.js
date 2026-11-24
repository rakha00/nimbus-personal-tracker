/// <reference path="../pb_data/types.d.ts" />

// Details filled from TMDB / Google Books when an item is picked from search.
migrate((app) => {
  const c = app.findCollectionByNameOrId("media_items");
  c.fields.add(new TextField({ name: "external_id", max: 100 }));   // "tmdb:550", "gbooks:abc"
  c.fields.add(new URLField({ name: "cover_url" }));
  c.fields.add(new TextField({ name: "synopsis", max: 10000 }));
  app.save(c);
}, (app) => {
  const c = app.findCollectionByNameOrId("media_items");
  for (const name of ["external_id", "cover_url", "synopsis"]) c.fields.removeByName(name);
  app.save(c);
});
