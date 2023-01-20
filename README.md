# PostgreSQL Logical Replication with Supabase
How to set up a read-only replica using PostgreSQL Logical Replication with Supabase.

Forked to automate the process from [/burggraf/postgresql_replicas](https://github.com/burggraf/postgresql_replicas).

### Step 1: Set up a new project in Supabase to host your replica database
[https://supabase.com](https://supabase.com)

### Step 2: Edit your data in the script:
```
ORIGINAL_DB_URL=db.original_project_ref.supabase.co
REPLICA_DB_URL=db.replica_project_ref.supabase.co
ORIGINAL_DB_PASS=secret_password_here
REPLICA_DB_PASS=secret_new_password_here
```

### Step 3: Run the script:

```bash
chmod +x create_replication.sh
./create_replication.sh
```


##  Debugging your replication
See [Debugging PostgreSQL Logical Replication](./debugging.md)

### Notes regarding database migrations / schema changes
- Be careful with schema changes, they don't propagate to the replicas automatically, and will cause the replica to stop syncing.
- If you use `DROP CASCADE` on the `public` schema when attempting to resync schemas, it can cause the `realtime.subscription` to drop.

## Acknowlegements
Thanks Mark that created the Original guide. Apud thanks to Colin from Zverse and for pointing out some of these great debugging techniques that help solve issues related to database migrations.
