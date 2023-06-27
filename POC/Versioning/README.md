# PoC Versioning

I think we have two potential options for versioning

1. Single version number in **root** (or in `header` in root), that is "trinkled down" via `userInfo` in Decoder/Encoder
2. Version number in **every single model**

**A solution is only viable if it also works for Android**

# Single version number trinkled down via `userInfo`

The idea is that we will bump the root version number if **any** child model changes and that we use it to have custom coding / migration logic in every model.

