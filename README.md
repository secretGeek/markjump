markjump
========

Powershell implementation of Mark &amp; Jump

Inspired by the [work of Jeroen Janssens](http://jeroenjanssens.com/2013/08/16/quickly-navigate-your-filesystem-from-the-command-line.html)

Four functions: **Mark**, **Jump**, **Unmark** and **Marks**.

With `mark`  you specify a friendly name for the current location. Then with `Jump {name}` you go back to it. Use `marks` to list all the names and locations you've marked. And with `unmark {name}` you can remove one from the list.

It includes aliases `m` for `mark`, `j` for `jump`, and `um` for `unmark`. 

_You might want to comment those out if they collide with other aliases you use_.


commands
------------
## `mark  [name]`

**alias: `m`**


**usage:**

`mark [name]`
>mark a location with a name, allowing you to get back there easily.

## `jump [name]`

**alias: `j`**


**usage:**

`jump [name]`
>set-location to the location that was previously marked with that name.


## `marks`


**usage:**

`marks`
>list all of the marks that have been set




## `unmark [name]`

**alias: `um`**


**usage:**

`unmark [name]`
>remove a mark from the list of marks

install
-------

1. Download `markjump.ps1`
2. Add this to your `$profile`: "`. .\markjump.ps1`"
