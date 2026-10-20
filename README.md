# P&L and Cash Flow Model

A shared P&L and cash flow model for each client. Static site in `public/`, data in Supabase.

## How access works

Each client has one model, reached through a private link of the form
`https://<site>/?m=<token>`. Anyone with the link can view and edit that client's model.
There is no login. The tables are locked, and the only things the browser can call are
`get_model` and `save_section`, which both check the token. Only a hash of the token is stored.

## Create a client model

Run in the Supabase SQL editor:

```sql
select public.create_client_model('Client name');
```

It returns the token once. Send the client `https://<site>/?m=<token>`.

## Setup

1. Apply `supabase/migrations/20261020000000_client_models.sql` to the project.
2. Put the project URL and publishable key in `public/config.js`.
3. Connect the repo to a Netlify site. It publishes `public/` with no build step.
