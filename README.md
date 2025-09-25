# DemoGen

DemoGen is an [Elixir](https://elixir-lang.org) library that acts as a _director_ for creating demo scenarios, primarily aimed at Elixir/Phoenix/Ecto SaaS applications.

## Getting Started

1. **Add DemoGen to your dependencies** in `mix.exs`:
   ```elixir
   def deps do
     [
       {:demo_gen, "~> 0.1"}
     ]
   end
   ```

2. **Create your first command module**:
   ```elixir
   defmodule MyApp.Demo.Commands.AddUser do
     @use DemoGen, command_name: "add_user"

     @impl DemoGen.Command
     def run(args, %{time: t, symbols: symbols} = context) do
       {:string, name} = Map.get(args, :name)
       {:symbol, as} = Map.get(args, :as)

       # Your app logic here
       {:ok, user} = MyApp.create_user(%{name: name, inserted_at: t})

       {:ok, %{context | symbols: Map.put(symbols, as, user)}}
     end
   end
   ```

3. **Write a simple script** (`demo.dgen`):
   ```
   add_user {as: alice name: "Alice Smith"}
   ```

4. **Run your demo**:
   ```elixir
   DemoGen.Runner.run_demo("demo.dgen",
     prefix: MyApp.Demo.Commands,
     repo: MyApp.Repo)
   ```

## Demo Scripts Are Screenplays

Just as a movie director works from a script to coordinate actors as they play out scenes, DemoGen uses a script to direct your application through a sequence of state changes that create a compelling demo scenario.

Think of it this way:
- Your DemoGen script is like a movie script
- The commands you implement (like `add_user`, `join_org`) are like stage directions and dialogue
- The entities you create and track with symbols (like users and organizations) are your actors
- The timeline features (like `@next_day` and `[09:00]`) are like scene markers
- The variables are like props that get reused across scenes

For example, when your script includes:
```
        alter_clock {D: -7}
[09:00] delete_org {org: "TechCorp"}
        add_org {as: company name: "TechCorp"}      # Direction to create a new actor
[09:15] add_user {as: alice name: "Alice"}          # Direction to create another actor
        join_org {user: alice org: company}         # Direction for Alice to join TechCorp
```

DemoGen directs this scene by:
1. Setting the clock back to last week
2. Setting the clock time to 9:00am
3. Deleting the existing demo org
4. Creating the TechCorp organization (a new actor) and giving it the symbol `company` (so the creation time will be 09:00 on the date 1 week ago)
5. Advancing the time to 9:15am
6. Creating a user "Alice" (a second actor) and giving it the symbol `alice`
7. Also at 9:15, have Alice join TechCorp

You can see how different application specific commands coordinate your products features to create a realistic demonstration scenario that can be reset & played out the same each time.

Because DemoGen manages the current time under the hood and supplies it to each command it's easy to manage the flow of time across the demo.

Your job is to write the script and implement an Elixir module for each command.

## Key Features

- **Timeline Control**: Set when each scene takes place
- **Stage Directions**: Clear commands that create and direct your actors
- **Cast of Actors**: Track and manage your created entities through symbols
- **Props Management**: Reuse values throughout your production
- **Reproducible Performances**: Same script, same result, every time

## The Script Language

### Directing the Actors (Commands)

Your script consists of a series of commands that create and coordinate your application objects:

```
command_name {arg1: value1, arg2: value2, ...}

# Examples:
add_user {as: alice name: "Alice"}              # Creating a new user
join_org {user: alice org: company}             # Adding the new user to an existing organisation
```

DemoGen passes a context map from command-to-command. Commands can register objects in the map under a symbolic name allowing them to be referred to later using that name (and avoiding having to query for objects later on). In our example `add_user` command we have implemented an `as:` parameter that specifies the symbol `alice` to bind the new user object to. The `join_org` command looks the object up using that symbol via the `user:` parameter.

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

### Values

Values represent attributes that your schema objects can take. DemoGen supports

bool: false|true
symbol: [a-zA-Z][a-zA-Z0-9_]* e.g. Leadership
numeric: -?dd(.dd)? e.g. 42, -2.5
string: "chars" e.g. "What is six times seven?"
const: $const_name
rel_time: 🕒[+-]n[wdhms] e.g. 🕒+1d-2h (uses the clock face unicode symbol, U+1F552)

rel_time values are used to specify datetimes relative to `t` the current time in the demo. For example if `t` is 11:00 then 🕒-2h specifies 09:00.

See the BNF for the parser for accurate specification of value types.

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

## Integrating With Your Project

Add :demo_gen to the list of dependencies in `mix.exs` as per the Getting Started section above.

Then create command modules for each command you want to use within your demo generator script. Here's an example of a command that adds an `%Org{}` schema object.:

```elixir
defmodule Radar.Demo.Commands.AddOrg do
  @use DemoGen, command_name: "add_org"

  @impl DemoGen.Command
  def run(args, %{time: t, symbols: symbols} = context) when is_map(args) do
    {:string, name} = Map.get(args, :name)
    {:string, subdomain} = Map.get(args, :subdomain)
    {:symbol, as} = Map.get(args, :as)

    with {:ok, %Org{} = org} <- Radar.Accounts.create_org(t, name, subdomain) do
      {:ok, %{context | symbols: Map.put(symbols, as, org)}}
    end
  end
end
```

It is important to `@use DemoGen` and set the `command_name` attribute to the match the command syntax to appear in the `.dgen` script file for invoking that command. In this case `add_org`.

Note that we get a symbol passed in the `as` argument that we use to bind the return value from our context function `create_org` into the global `symbols:` map. This map is shared with all subsequent commands. This allows later commands to refer, by symbol name, to objects created by earlier commands.

A command should either return the tuple `{:ok, context}` where `context` is a possibly modified version of the data structure passed to the `run` function. Or `{:error, reason}` if command processing fails.

### Managing Time

By default Ecto will use the current datetime for insert or update operations which is not what we want. The `DemoGen.Ecto` module implements `set_timestamps(t)` which ensures that any Ecto records created by a command uses the right `inserted_at` and `updated_at` values. For example:

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

DemoGen provides the built in commands `set_clock` and `alter_clock` to manage the wall-clock time with the `[hh:mm]` syntax being a shortcut for setting the clock.

## Running Demo Scripts

To run a script:

```elixir
DemoGen.Runner.run_demo("path/to/script.dgen", prefix: Radar.Demo.Commands, repo: Radar.Repo)
```

The `prefix` option either specifies the single namespace, or a list of such namespaces, that your command implementing modules are under.

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

## BNF

Here is the DemoGen parser in BNF form (omitting whitespace parsing for overall clarity):

  program ::= statement*

  statement ::= clock_expr
              | macro_define
              | const_define
              | command
              | macro_expansion

  ; Identifiers
  identifier ::= id_initial_char id_char*
  id_initial_char ::= [a-zA-Z]
  id_char ::= [a-zA-Z0-9_]

  ; Values
  value ::= bool_value
          | symbol_value
          | numeric_value
          | string_value
          | reltime_value
          | const_ref

  bool_value ::= "true" | "false"
  symbol_value ::= identifier
  numeric_value ::= number
  string_value ::= '"' non_dquote* '"'
  non_dquote ::= [^"]

  ; Constants
  const_ref ::= "$" identifier
  const_define ::= "$" identifier "=" value

  ; Relative time
  reltime_value ::= "🕒" time_modifier+
  time_modifier ::= ("+" | "-") number ("w" | "d" | "h" | "m" | "s")

  ; Attributes
  attribute ::= identifier ":" value
  attributes ::= "{" attribute* "}"

  ; Commands
  command ::= identifier attributes

  ; Clock expressions
  clock_expr ::= "[" numeric_value ":" numeric_value (":" numeric_value)? "]"

  ; Macros
  macro_define ::= "macro" identifier "=" identifier attributes
  macro_expansion ::= "@" identifier

  ; Terminal symbols
  number ::= [0-9]+ ("." [0-9]+)?

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

PR's welcome.

## Credits

Matt Mower <matt@agendascope.com>
CEO, AgendaScope
