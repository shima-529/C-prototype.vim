# C-prototype.vim
##How C-prototype works
This plugin sort of releases you from substantial compile errors.

When you write a code of C or C++, it should be annoying to add prototype declarations.  
Even if you've forgotten to write them, why the compiler says, " **conflicting types for 'func'** " ????  
**Are you kidding me??**

If you make the most use of this plugin, just type `z` in normal mode. Prototype delerations will automatically add after pre-processor sentences.

## Installation
Installation is easy. Add `shima-529/C-prototype.vim` in your `.vimrc` in order to run by the package manager you use.  
If you use `NeoBundle`, type as follows:
```vim
NeoBundleLazy 'shima-529/C-prototype.vim', {
	\ 'autoload' : {'filetypes' : ['c']}
	\ }
```
After adding it, run vim and type `:NeoBundleInstall`.  
Because of the structure of a code, you should not add `cpp` to the `filetypes` section below.

##Usage
When you finished writing the entire code, just type `z` in normal mode. That's all!!

`z` command goes far from just adding. After editing functions themselves, if you type `z`, the prototypes will be refreshed.

If you want to delete prototypes, type `dz`. This deletes them including a line feed.

Here is how they work:

![pic](./proto.gif "pic")


##Attention
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

void func1(void);puts("Hello World!");}							// <---- Added
void func2(char *param);	printf("Fxxk you, %s!!\n", param);	// <---- Added
int main(void){
	func1();
	func2("Guy");
	return 0;
}

void func1(void){puts("Hello World!");}

void func2(char *param){	printf("Fxxk you, %s!!\n", param);
}
```
