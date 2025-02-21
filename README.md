# DemoGen

DemoGen is an [Elixir](https://elixir-lang.org) library that acts as a _director_ for creating demo scenarios for Elixir/Phoenix/Ecto application. Just as a movie director works from a script to coordinate actors as they play out scenes, DemoGen uses a script to direct your application through a sequence of state changes that create a compelling demo scenerio for your prospects.

Think of it this way:
- Your DemoGen script is like a movie script
- The commands you implement (like `add_user`, `join_org`) are like stage directions and dialogue
- The entities you create and track with symbols (like users and organizations) are your actors
- The timeline features (like `@next_day` and `[09:00]`) are like scene markers
- The variables are like props that get reused across scenes

For example, when your script includes:
```
delete_org {org: "TechCorp"}
[09:00] add_org {as: company name: "TechCorp"}      # Direction to create a new actor
[09:15] add_user {as: alice name: "Alice"}          # Direction to create another actor
        join_org {user: alice org: company}         # Direction for Alice to join TechCorp
```

DemoGen directs this scene by:
1. Deleting the existing demo org
2. Setting the scene time to 9:00
3. Creating the TechCorp organization (a new actor) and giving it the symbol `company`
4. Advacing the time to 9:15
5. Creating a user "Alice" (a second actor) and giving it the symbol `alice`
6. Also at 9:15, have Alice join TechCorp

You can see how different application specific commands coordinate your products features to create a realistic demonstration scenario that can be reset & played out the same each time.

Your job is to write the script and implement an Elixir module for each command.

## Key Features

- **Timeline Control**: Set when each scene takes place
- **Stage Directions**: Clear commands that create and direct your actors
- **Cast of Actors**: Track and manage your created entities through symbols
- **Props Management**: Reuse values throughout your production
- **Reproducible Performances**: Same script, same result, every time

## The Script Language

### Stage Directions

Your script consists of stage directions that create and coordinate your actors:

```
command_name {arg1: value1, arg2: value2, ...}  # A stage direction

# Examples:
add_user {as: alice name: "Alice"}              # Creating a new actor
join_org {user: alice org: company}             # Directing an actor to act
```

In our examples we implement an `as:` parameter to the `add_user` command that specifies a symbol that DemoGen will bind the new object to. These symbols are held in a context that is passed from command to command meaning that later commands can refer to previously created objects by symbol.

This avoids the need to manually consider ID's or looking objects up.

### Setting the Scene (Time Control)

DemoGen provides each command with the _current time_ when it is being run. This gives us ways to control when things happen:

```
# Move to a different time
alter_clock {D: +1}  # Tomorrow's scene
alter_clock {M: -1}  # Last month's scene

# Create shorthand for common time jumps
macro last_month = alter_clock {M: -1}
macro next_day = alter_clock {D: +1}

# Set specific times for scenes
[09:00] first_scene {...}
[09:15] next_scene {...}
```

When a script begins the _current time_ is the wall clock time. So your first clock command is likely to be an `alter_clock` to set the date/time when the demo begins.

### Props (Variables)

Define reusable props with the `$` prefix:

```
$password = "secure-password"
$location = "headquarters"

add_user {name: "John", password: $password, location: $location}
```

### The Cast (Symbols)

Symbols represent the actors in your production - the actual entities that perform your demo:

```
add_org {as: company name: "TechCorp"}  # Introduce TechCorp as an actor
add_user {as: alice name: "Alice"}      # Introduce Alice as an actor
join_org {user: alice org: company}     # Alice and TechCorp perform together
```

Each symbol (company, alice) represents an actual actor that can be directed to perform actions throughout your script.

## How DemoGen Directs Your Application

DemoGen is like a director interpreting a script and giving life to a performance. Here's how a scene plays out:

1. You write a stage direction: `add_org {as: company name: "TechCorp"}`
2. DemoGen, as director, interprets this as:
   - What kind of action to perform ("add_org")
   - What actor to create (a new organization named "TechCorp")
   - When this should happen (the current timeline position)
3. It passes these directions to your `YourApp.Demo.Commands.AddOrg` module
4. Your application creates the actual actor (the organization)
5. DemoGen records this new actor as 'company' in its cast (symbols)
6. This actor can now be directed to perform other actions throughout your script

## Implementing Stage Directions (Integration)

Add :demogen to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:demogen, "~> 0.1"}
  ]
end
```

Then create command modules for each command you want to use within your demo generator script. Here's an example:

```elixir
defmodule Radar.Demo.Commands.AddOrg do
  @use DemoGen, command_name: "add_org"

  @impl DemoGen.Command
  def run(args, %{time: t, symbols: symbols}) when is_map(args) do
    {:string, name} = Map.get(args, :name)
    {:string, subdomain} = Map.get(args, :subdomain)
    {:symbol, as} = Map.get(args, :as)

    with {:ok, %Org{} = org} <- Radar.Accounts.create_org(t, name, subdomain) do
      {:ok, %{context | symbols: Map.put(symbols, as, org)}}
  end
end
```

Note that we get a symbol pass in the `as` argument that we use to bind the return value from our context function `create_org` into our global `symbols:` map. This allows later commands to refer, by name, to objects created by earlier commands.

The `DemoGen.Ecto` module implements `set_timestamps(t)` which ensures that any Ecto records created by a command uses the right `inserted_at` and `updated_at` values. For example:

```elixir
defp create_org(t, name, subdomain) do
  %Org{}
  |> Org.create_changeset(%{
    "name" => name,
    "subdomain" => subdomain
  })
  |> demo_changeset(%{
    "demo" => true
  })
  |> Command.set_timestamps(t)
  |> Repo.insert()
end
```

To run a script:

```elixir
DemoGen.Runner.run_demo("path/to/script.dgen", prefix: Radar.Demo.Commands, repo: Radar.Repo)
```

The `prefix` option specifies the namespace that your command implementing modules are under. At the moment only one such namespace prefix is supported.

DemoGen runs all commands within the context of an Ecto transaction and the `repo` option should specify your application repo instance.

## Example Production

Here's a complete script demonstrating a typical DemoGen production:

```
# Set up our props
$subdomain = "demo"
$password = "demo-pass"

# Scene timing directions
macro last_month = alter_clock {M: -1}
macro next_day = alter_clock {D: +1}

# Start our story one month ago
@last_month

# Scene 1: Company Formation
[09:00] add_org {as: org name: "Demo Corp" subdomain: $subdomain}
        set_feature_flag {org: org flag: "beta_features"}

# Scene 2: The Early Employees
@next_day

[09:00] add_user {as: alice name: "Alice Smith" email: "alice@demo.com" password: $password}
        join_org {user: alice org: org admin: true}

[09:30] add_user {as: bob name: "Bob Jones" email: "bob@demo.com" password: $password}
        join_org {user: bob org: org admin: false}
```

## Best Practices

1. **Scene Management**
   - Start with a clear temporal anchor (e.g., `@last_month`)
   - Use consistent scene transitions (`@next_day`)
   - Mark moments where things happen `[HH:MM]`

2. **Script Organization**
   - Group related stage directions into scenes
   - Use consistent indentation for related actions
   - Comment scene changes and major plot points

3. **Cast and Props Management**
   - Give your actors (symbols) meaningful names
   - Track which actors are in each scene
   - Use props to maintain consistency across scenes
   - Document when new actors join the production

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

[Your contribution guidelines]

## Credits

Matt Mower <matt@agendascope.com>
CEO AgendaScope
