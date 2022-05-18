

### [local provider](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)

- This is a block. A block has a type `resource`. 
- It's a _resource type block_.
- Each block has defined multiple `labels`.
  - In our case we have 2 labels:
    - The first one `local_file` is the resource type
      - The resource type is coming from the provider, in this case, the `local` provider
    - The second one `foo` is the resource name
      - Is our choice the resource name. Can be a local file or etc
- The we have the **block body** defined by the `{ }`
  - Within the block body further blocks and arguments can be nested.
    - Some arguments can be optional and other are required. Check `provider` and `module` doc for reference.
  - In our case we have 2 arguments:
    - `content`
    - `filename`

```
resource "local_file" "foo" {
    content     = "foo!"
    filename = "${path.module}/foo.bar"
}
```
