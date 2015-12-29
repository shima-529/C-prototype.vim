# C-prototype.vim
##How C-prototype works
This plugin sort of releases you from substantial compile errors.

When you write a code of C or C++, it should be annoying to add prototype declarations.  
If you've forgotten to write them, why the compiler says, " **conflicting types for 'func'** "  
**This is very annoying!**

If you make the most use of this plugin, just type `z` in normal mode. Prototype delerations will be automatically added just before `main` function.

## Installation
Installation is easy. Add `shima-529/C-prototype.vim` in your `.vimrc` in order to run by the package manager you use.  
If you use `NeoBundle`, type as follows:
```vim
NeoBundleLazy 'shima-529/C-prototype.vim', {
	\ 'autoload' : {'filetypes' : ['c']}
	\ }
```
After adding it, run vim and type `:NeoBundleInstall`.  
Because of the structure of a code, I do not recommend adding `cpp` to the `filetypes` section below.

##Usage

**You can change these key bindings. Please see the next section.**

When you finished writing the entire code, just type `z` in normal mode. That's all!!

`z` command goes far from just adding. After editing functions themselves, if you type `z`, the prototypes will be refreshed.

If you want to delete prototypes, type `dz`. This deletes them including a line feed.

Here is how they work:

![pic](./proto.gif "pic")

##Settings
###1. Key Bindings

If you want to use `z` as a default, you need not do anything.  
However, `z` is a very useful key. If you do not like to override it, you can set bindings on your `.vimrc`.

e.g. )

```Vim
nmap M <Plug>(c-prototype-make)
nmap dM <Plug>(c-prototype-delete)
let g:c_prototype_no_default_keymappings = 1
```
Note that the last line is needed to apply changes.

Or you can use without setting the bindings. In this case, add `let g:c_prototype_no_default_keymappings = 1` to your `.vimrc`.  
`:CPrototypeMake` makes prototypes and `:CPrototypeDelete` deletes them.

###2. Temporary Disabling

If you want to disable this plugin without deleting the settings or commenting out, add `let g:loaded_C_prototype = 1`. This prevents this plugin from being loaded.

##Attention(known bugs)
If you did not insert line feeds after **`{`**, this plugin does not work.

**N.G.)**
```C
#include <stdio.h>
int main(void){
	func1();
	func2("Guy");
	return 0;
}

void func1(void){puts("Hello World!");}

void func2(char *param){	printf("Fxxk you, %s!!\n", param);
}
```
By typing `z`, this changes as follows.
```C
#include <stdio.h>

void func1(void)	// <---- Added
void func1(void)	// <---- Added

int main(void){
	func1();
	func2("Guy");
	return 0;
}

void func1(void){puts("Hello World!");}

void func2(char *param){	printf("Fxxk you, %s!!\n", param);
}
```
