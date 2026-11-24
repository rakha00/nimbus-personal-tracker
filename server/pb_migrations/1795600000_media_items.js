/// <reference path="../pb_data/types.d.ts" />

// Media log: films and books, either on the wishlist or done.
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const OWN = "owner = @request.auth.id";
  const c = new Collection({
    type: "base", name: "media_items",
    listRule: OWN, viewRule: OWN, deleteRule: OWN,
    createRule: '@request.auth.id != "" && @request.body.owner = @request.auth.id',
    updateRule: OWN + " && (@request.body.owner:isset = false || @request.body.owner = @request.auth.id)",
    fields: [
      { name: "owner", type: "relation", collectionId: users.id, required: true, maxSelect: 1, cascadeDelete: true },
      { name: "type", type: "select", required: true, maxSelect: 1, values: ["film", "book"] },
      { name: "title", type: "text", required: true, max: 200 },
      { name: "creator", type: "text", max: 200 },
      { name: "year", type: "number", onlyInt: true, min: 1800, max: 2200 },
      { name: "status", type: "select", required: true, maxSelect: 1, values: ["wishlist", "done"] },
      { name: "finished_on", type: "date" },
      { name: "rating", type: "number", onlyInt: true, min: 1, max: 5 },
      { name: "note", type: "text", max: 5000 },
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
    ],
    indexes: ["CREATE INDEX idx_media_owner_status ON media_items (owner, status)"],
  });
  app.save(c);
}, (app) => {
  app.delete(app.findCollectionByNameOrId("media_items"));
});
