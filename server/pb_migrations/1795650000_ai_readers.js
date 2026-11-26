/// <reference path="../pb_data/types.d.ts" />

// AI assist: a read-only login for the AI worker. It can read its owner's records and nothing
// else; every create/update/delete rule still requires a `users` login, so the DB refuses writes.
const OWNED = ["accounts", "transactions", "diary_entries", "media_items", "calendar_events"];
const OWN = "owner = @request.auth.id";
const READ = OWN + ' || (@request.auth.collectionName = "ai_readers" && owner = @request.auth.owner)';
const AUTHED = '@request.auth.id != ""';
const USER = '@request.auth.collectionName = "users"';

migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const readers = new Collection({
    type: "auth", name: "ai_readers",
    listRule: "id = @request.auth.id", viewRule: "id = @request.auth.id",
    createRule: null, updateRule: null, deleteRule: null, // admin panel only
    fields: [{ name: "owner", type: "relation", collectionId: users.id, required: true, maxSelect: 1, cascadeDelete: true }],
  });
  app.save(readers);

  for (const name of OWNED) {
    const c = app.findCollectionByNameOrId(name);
    c.listRule = READ;
    c.viewRule = READ;
    app.save(c);
  }

  // Categories were writable by any login; keep reads open, writes to the app user only.
  const categories = app.findCollectionByNameOrId("categories");
  categories.createRule = USER;
  categories.updateRule = USER;
  categories.deleteRule = USER;
  app.save(categories);
}, (app) => {
  for (const name of OWNED) {
    const c = app.findCollectionByNameOrId(name);
    c.listRule = OWN;
    c.viewRule = OWN;
    app.save(c);
  }
  const categories = app.findCollectionByNameOrId("categories");
  categories.createRule = AUTHED;
  categories.updateRule = AUTHED;
  categories.deleteRule = AUTHED;
  app.save(categories);
  app.delete(app.findCollectionByNameOrId("ai_readers"));
});
