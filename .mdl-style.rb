all
# Tables and code blocks cannot wrap, so the line limit is for prose only.
rule 'MD013', :tables => false, :ignore_code_blocks => true
# Number list items 1, 2, 3, so the plain text reads like the rendered page.
rule 'MD029', :style => :ordered
# Go code uses tabs (gofmt), so allow tabs inside code blocks.
rule 'MD010', :ignore_code_blocks => true
