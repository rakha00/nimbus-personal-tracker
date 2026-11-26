/// <reference path="../pb_data/types.d.ts" />

// AI assist queue: the app adds a request, the AI worker (an ai_readers login) fills in the result.
// Empty status = waiting. The worker may only set the result fields, never the prompt or owner.
migrate((app) => {
  const users = app.findCollectionByNameOrId("users");
  const OWN = "owner = @request.auth.id";
  const READER = '@request.auth.collectionName = "ai_readers" && owner = @request.auth.owner';
  const c = new Collection({
    type: "base", name: "ai_requests",
    listRule: `${OWN} || (${READER})`, viewRule: `${OWN} || (${READER})`,
    createRule: '@request.auth.collectionName = "users" && @request.body.owner = @request.auth.id',
    updateRule: READER + " && @request.body.owner:isset = false && @request.body.mode:isset = false && @request.body.prompt:isset = false",
    deleteRule: OWN,
    fields: [
      { name: "owner", type: "relation", collectionId: users.id, required: true, maxSelect: 1, cascadeDelete: true },
      { name: "mode", type: "select", required: true, maxSelect: 1, values: ["record", "ask"] },
      { name: "prompt", type: "text", required: true, max: 500 },
      { name: "status", type: "select", maxSelect: 1, values: ["running", "done", "error"] },
      { name: "answer", type: "text", max: 5000 },
      { name: "drafts", type: "json", maxSize: 20000 },
      { name: "error", type: "text", max: 500 },
      { name: "created", type: "autodate", onCreate: true },
      { name: "updated", type: "autodate", onCreate: true, onUpdate: true },
    ],
    indexes: ["CREATE INDEX idx_ai_requests_status ON ai_requests (status, created)"],
  });
  app.save(c);
}, (app) => {
  app.delete(app.findCollectionByNameOrId("ai_requests"));
});
