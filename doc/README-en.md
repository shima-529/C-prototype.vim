# C-prototype.vim
##How C-prototype works
This plugin sort of releases you from substantial compile errors.

When you write a code of C or C++, it should be annoying to add prototype declarations.  
If you've forgotten to write them, why the compiler says, " **conflicting types for 'func'** "  
**This is very annoying!**

If you make the most use of this plugin, just type <kbd>z</kbd> in normal mode. Prototype delerations will be automatically added just before `main` function.

## Installation
Installation is easy. Add `shima-529/C-prototype.vim` in your `.vimrc` in order to run by the package manager you use.Otherwise please run `git clone`.  
If you use `NeoBundle`, type as follows:
```vim
NeoBundleLazy 'shima-529/C-prototype.vim', {
	\ 'autoload' : {'filetypes' : ['c', 'cpp']}
	\ }
```
After adding it, run vim and type `:NeoBundleInstall`.  
Because of the structure of a code, I do not recommend adding `cpp` to the `filetypes` section below.

##Usage

**You can change these key bindings. Please see the next section.**

When you finished writing the entire code, just type <kbd>z</kbd> in normal mode. That's all!!

<kbd>z</kbd> command goes far from just adding. After editing functions themselves, if you type <kbd>z</kbd>, the prototypes will be refreshed.

If you want to delete prototypes, type <kbd>d</kbd><kbd>z</kbd>. This deletes them.

In Ex mode, `:CPrototypeMake` means the same as <kbd>z</kbd> and `:CPrototypeDelete` means the same as <kbd>d</kbd><kbd>z</kbd>.

<!-- Here is how they work:

![pic](./proto.gif "pic") -->

##Settings
###1. Key Bindings

If you want to use <kbd>z</kbd> as a default, you need not do anything.  
However, <kbd>z</kbd> is a very useful key. If you do not like to override it, you can set bindings on your `.vimrc`.

e.g. )

```Vim
nmap M <Plug>(c-prototype-make)
nmap dM <Plug>(c-prototype-delete)
let g:c_prototype_no_default_keymappings = 1
```
Note that the last line is needed to apply changes.

Or you can use without setting the bindings. In this case, set `let g:c_prototype_no_default_keymappings = 1` in your `.vimrc`.  
`:CPrototypeMake` makes prototypes and `:CPrototypeDelete` deletes them.

###2. Temporary Disabling

If you want to disable this plugin without deleting the settings or commenting out, set `let g:loaded_C_prototype = 1`. This prevents this plugin from being loaded.

###3. Variable Name

In the prototypes, you have only to demonstrate variable types --- without variable names. If you prefer it, set `let g:c_prototype_remove_var_name = 1`.

###4. Insert Position

If you set `let g:c_prototype_insert_point = 1`, `:CPrototypeMake` inserts a line feed after all prototypes.