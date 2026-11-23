/// <reference path="../pb_data/types.d.ts" />

// Nimbus v1 schema: accounts, categories, transactions, diary_entries.
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  // Personal app: no public sign-up, accounts are created from the admin panel.
  users.createRule = null;
  app.save(users);

  const OWN = "owner = @request.auth.id";
  const CREATE = '@request.auth.id != "" && @request.body.owner = @request.auth.id';
  const UPDATE = OWN + " && (@request.body.owner:isset = false || @request.body.owner = @request.auth.id)";
  const AUTHED = '@request.auth.id != ""';

  const owner = { name: "owner", type: "relation", collectionId: users.id, required: true, maxSelect: 1, cascadeDelete: true };
  const timestamps = [
    { name: "created", type: "autodate", onCreate: true },
    { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
  ];
  const owned = (name, fields, indexes = []) => {
    const c = new Collection({
      type: "base", name,
      listRule: OWN, viewRule: OWN, createRule: CREATE, updateRule: UPDATE, deleteRule: OWN,
      fields: [owner, ...fields, ...timestamps],
      indexes,
    });
    app.save(c);
    return c;
  };

  const accounts = owned("accounts", [
    { name: "name", type: "text", required: true, max: 100 },
    { name: "type", type: "select", required: true, maxSelect: 1, values: ["cash", "bank", "ewallet"] },
    { name: "opening_balance", type: "number", onlyInt: true },
  ]);

  // ponytail: categories are shared (no owner) since there's one user; add owner if the app ever goes multi-user.
  const categories = new Collection({
    type: "base", name: "categories",
    listRule: AUTHED, viewRule: AUTHED, createRule: AUTHED, updateRule: AUTHED, deleteRule: AUTHED,
    fields: [
      { name: "name", type: "text", required: true, max: 100 },
      { name: "kind", type: "select", required: true, maxSelect: 1, values: ["income", "expense"] },
      ...timestamps,
    ],
    indexes: ["CREATE UNIQUE INDEX idx_categories_kind_name ON categories (kind, name)"],
  });
  app.save(categories);

  const seed = {
    expense: ["Makan & Minum", "Jajan", "Transport", "Listrik & Air", "Pulsa & Internet", "Belanja", "Kesehatan", "Hiburan", "Langganan", "Lainnya"],
    income: ["Gaji", "Bonus", "Hadiah", "Lainnya"],
  };
  for (const [kind, names] of Object.entries(seed)) {
    for (const name of names) {
      const r = new Record(categories);
      r.set("name", name);
      r.set("kind", kind);
      app.save(r);
    }
  }

  owned("transactions", [
    { name: "date", type: "date", required: true },
    { name: "type", type: "select", required: true, maxSelect: 1,
      values: ["income", "expense", "transfer", "lend", "collect", "borrow", "repay"] },
    { name: "amount", type: "number", required: true, onlyInt: true, min: 1 },
    // Empty account = debt that predates tracking, so it doesn't touch any balance.
    { name: "account", type: "relation", collectionId: accounts.id, maxSelect: 1 },
    { name: "to_account", type: "relation", collectionId: accounts.id, maxSelect: 1 },
    { name: "category", type: "relation", collectionId: categories.id, maxSelect: 1 },
    { name: "person", type: "text", max: 100 },
    { name: "note", type: "text", max: 500 },
  ], [
    "CREATE INDEX idx_transactions_owner_date ON transactions (owner, date)",
  ]);

  owned("diary_entries", [
    { name: "date", type: "date", required: true },
    { name: "content", type: "text", required: true, max: 100000 },
  ], [
    "CREATE UNIQUE INDEX idx_diary_owner_date ON diary_entries (owner, date)",
  ]);
}, (app) => {
  for (const name of ["diary_entries", "transactions", "categories", "accounts"]) {
    app.delete(app.findCollectionByNameOrId(name));
  }
  const users = app.findCollectionByNameOrId("users");
  users.createRule = "";
  app.save(users);
});
