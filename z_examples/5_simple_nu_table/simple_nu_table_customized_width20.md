```nushell
> $env.numd?
```

```nushell
[[a b c]; [1 2 3]]
```

Output:

```
# => ╭─#─┬─a─┬─b─┬─c─╮
# => │ 0 │ 1 │ 2 │ 3 │
# => ╰─#─┴─a─┴─b─┴─c─╯
```

```nushell
[[column long_text];

['value_1' ('Veniam cillum et et. Et et qui enim magna. Qui enim, magna eu aute lorem.' +
                'Eu aute lorem ullamco sed ipsum incididunt irure. Lorem ullamco sed ipsum incididunt.' +
                'Sed ipsum incididunt irure, culpa. Irure, culpa labore sit sunt.')]

['value_2' ('Irure quis magna ipsum anim. Magna ipsum anim aliquip elit lorem ut. Anim aliquip ' +
                'elit lorem, ut quis nostrud. Lorem ut quis, nostrud commodo non. Nostrud commodo non ' +
                'cillum exercitation dolore fugiat nulla. Non cillum exercitation dolore fugiat nulla ' +
                'ut. Exercitation dolore fugiat nulla ut adipiscing laboris elit. Fugiat nulla ut ' +
                'adipiscing, laboris elit quis pariatur. Adipiscing laboris elit quis pariatur. ' +
                'Elit quis pariatur, in ut anim anim ut.')]
]
```

Output:

```
# => ╭─#─┬─column─┬─...─╮
# => │ 0 │ value… │ ... │
# => │ 1 │ value… │ ... │
# => ╰─#─┴─column─┴─...─╯
```
