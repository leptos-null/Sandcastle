# Sandcastle

Sandcastle is a prototype iOS app built on top of the [Gemini Live API](<https://ai.google.dev/gemini-api/docs/live>).

## Tools

In particular, the app aims to demonstrate [Tool use](<https://ai.google.dev/gemini-api/docs/live-tools>).

To demonstrate Tool use, the app includes a UI called "playground" which can be interacted with via Tools with the following pseudo-code declarations:

```ts
/// Set if the playground should be shown to the user
function playground_set_is_showing(boolean should_show) -> ()
```

```ts
enum Color {
    black
    blue
    brown
    cyan
    gray
    green
    indigo
    mint
    orange
    pink
    purple
    red
    teal
    white
    yellow
}

/// Set the color used in the playground
function playground_set_color(enum Color color) -> ()
```

The user could use the prompt "Please set the playground to the color that trees are commonly depicted as", which likely would result in the Tool call: `playground_set_color(Color.green)`

## Demo

https://github.com/user-attachments/assets/299b8536-b64d-4205-a637-79841852d1a0
