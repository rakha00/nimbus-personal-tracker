/// <reference path="../pb_data/types.d.ts" />

// A film or book picked from search can be saved once; manual items (no external_id) are not checked.
migrate((app) => {
  const c = app.findCollectionByNameOrId("media_items");
  c.addIndex("idx_media_owner_external", true, "owner, external_id", "external_id != ''");
  app.save(c);
}, (app) => {
  const c = app.findCollectionByNameOrId("media_items");
  c.removeIndex("idx_media_owner_external");
  app.save(c);
});
