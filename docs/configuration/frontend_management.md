# Frontend Management

Frontends in Akkoma are swappable, and you can have as many as you like.

For a basic setup, you can set a frontends for the key `primary` and `admin` and the options of `name` and `ref`. This will then make Akkoma serve the frontend from a folder constructed by concatenating the instance static path, `frontends` and the name and ref.

The key `primary` refers to the frontend that will be served by default for general requests. The key `admin` refers to the frontend that will be served at the `/pleroma/admin` path.

If you don't set anything here, you will not have _any_ frontend at all.

Example:

```elixir
config :pleroma, :frontends,
  primary: %{
    "name" => "pleroma",
    "ref" => "stable"
  },
  admin: %{
    "name" => "admin",
    "ref" => "develop"
  },
  dwarves: %{
    "name" => "diggydiggy",
    "ref" => "hole"
  },
  extra: [
    %{"subdomain" => "dwarves", "key" => :dwarves}
  ]
```

This would serve the frontend from the the folder at `$instance_static/frontends/pleroma/stable`. You have to copy the frontend into this folder yourself. You can choose the name and ref any way you like, but they will be used by mix tasks to automate installation in the future, the name referring to the project and the ref referring to a commit.

Refer to [the frontend CLI task](../../administration/CLI_tasks/frontend) for how to install the frontend's files

If you wish masto-fe to also be enabled, you will also need to run the install task for `mastodon-fe`. Not doing this will lead to the frontend not working.

If you choose not to install a frontend for whatever reason, it is recommended that you enable [`:static_fe`](#static_fe) to allow remote users to click "view remote source". Don't bother with this if you've got no unauthenticated access though.

You can also replace the default "no frontend" page by placing an `index.html` file under your `instance/static/` directory.

## Installing multiple frontends

If you want to have more than one frontend, you can, via the magic of subdomains.

You'll need to do a few things to get this to work. 

1. Point the new subdomain at your akkoma IP - you can probably just use a CNAME record to make the new subdomain map to your base domain
2. Ensure your SSL certificate covers the subdomain - you can either have one big SSL certificate with 2 domains, or two certificates. Either will work.
3. Make your webserver direct the domain to akkoma.

    This can be done in a few different ways depending on your setup. If you have
one single SSL certificate covering both domain and subdomain, you can
add the subdomain to nginx's `server_name` line, so it reads `server_name akkoma.dev subdomain.akkoma.dev`. 

    If you have two seperate SSL certificates, you will need to copy the webserver
configuration to make a new `server {}` block, and change the `server_name` and `ssl_certificate` parameters as appropriate.

4. Install the frontend - either use [the frontend CLI task](../../administration/CLI_tasks/frontend), or place distribution files at `$instance_dir/frontends/$name/$ref`
5. Modify the [configuration](../cheatsheet#frontends) - you should have a new entry in `extra` which references the subdomain we'll be serving on in `"subdomain"`, and a reference to the top-level `"key"` which will be served. 
