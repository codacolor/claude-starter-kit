# Hub-and-Spoke Workspace

This workspace uses a hub-and-spoke model. One folder is the hub. Everything inside is organized into a few clear buckets so things stay findable as the workspace grows.

## The buckets

- **Areas/** — long-running domains of work with no end date (e.g. "Writing", "Finances", "Home Projects"). Each Area is self-contained: its own notes, files, and (optionally) its own `CLAUDE.md` describing what it is and how to work in it. If an Area ever moves elsewhere, everything it needs travels with it.
- **Projects/** — time-bounded work with a clear finish line. Date-prefix them (`YYYYMMDD Name`) so they sort chronologically. When a Project is done, it can be archived. If a Project keeps growing with no end in sight, promote it to an Area.
- **Global Utilities/** — tools, scripts, or infrastructure shared across multiple Areas. If only one Area uses it, it belongs inside that Area instead.
- **Templates/** — reusable starting points for new Areas and Projects.

## Where does new work go?

Ask in order:

1. Does it serve multiple Areas? → **Global Utilities/**
2. Is it an ongoing domain with no end date? → **Areas/**
3. Is it time-bounded with a clear endpoint? → **Projects/YYYYMMDD Name/**
4. Is it a reusable starting point? → **Templates/**

## Keep CLAUDE.md lean

The root `CLAUDE.md` is a map, not an encyclopedia. It says what the workspace is and how to work in it. Detailed, domain-specific knowledge goes inside the relevant Area's own `CLAUDE.md`, not the root. For each line in a CLAUDE.md, ask: "Would removing this cause a mistake?" If not, cut it.

## Don't build ahead of need

Don't pre-create empty Area folders or scaffolding for work that doesn't exist yet. Structure should follow real work, not precede it. Start small. Add buckets as you fill them.
