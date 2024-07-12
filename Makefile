
# dot-target = $(dir $@).$(notdir $@)
# # $@：这是一个自动变量，代表当前规则中的目标文件名。
# # $(dir $@)：这是dir函数的使用，它接受一个文件名作为参数，并返回该文件名的目录部分（包括尾部的斜杠，如果有的话）。
# # 如果文件名没有目录部分（即它是一个相对路径或绝对路径的基名），则dir函数返回.（当前目录）。
# # $(notdir $@)：这是notdir函数的使用，它接受一个文件名作为参数，并返回不包含目录部分的文件名。
# # 如果文件名是一个纯文件名（没有路径），则notdir函数简单地返回该文件名。
# # $(dir $@).$(notdir $@)：通过将dir和notdir函数的输出用.连接起来，这个表达式实际上是在重新构造原始的目标文件名
# # 例如，如果$@是src/main.o，那么：
# # $(dir $@)将是src/
# # $(notdir $@)将是main.o
# # 因此，$(dot-target)将是src/.main.o

# depfile = $(subst $(comma),_,$(dot-target).d)
# # $(subst $(comma),_,$(dot-target).d)：这是subst函数的使用示例。
# # subst函数有三个参数：要查找的字符串、要替换成的字符串、原始字符串。
# # 在这个例子中，它查找$(dot-target).d中的逗号（,），并将每个逗号替换为下划线（_）。


TARGET := test

all: $(TARGET)

SRCS          := $(wildcard ./*.c) 
OBJS          := $(SRCS:.c=.o)  
add_fixdep    := 1
fixdep_method := 3

%.o: %.c  
	gcc -c -MD $< -o $@  

ifeq ($(add_fixdep),0)
$(TARGET): $(OBJS)
	gcc $^ -o $@
else

DEPS        := $(SRCS:.c=.d)  
comma       := ,
dot-target   = $(dir $@)$(notdir $@)
depfile      = $(subst $(comma),_,$(dot-target).d)

-include $(DEPS)  

ifeq ($(fixdep_method),0)
$(TARGET): $(OBJS)  
	./basic/fixdep $(depfile) $@ "gcc $^ -o $@" > $(dot-target).tmp
	mv -f $(dot-target).tmp $(dot-target).cmd
	gcc $^ -o $@
endif

ifeq ($(fixdep_method),1)
define rule_cc_o_c
	./basic/fixdep $(depfile) $@ 'gcc $^ -o $@' > $(dot-target).tmp;  \
	mv -f $(dot-target).tmp $(dot-target).cmd
endef
$(TARGET): $(OBJS)
	$(call rule_cc_o_c)
	gcc $^ -o $@
endif

ifeq ($(fixdep_method),2)
arg-check = $(if $(strip $(cmd_$@)),,1)
any-prereq = $(filter-out $(PHONY),$?) $(filter-out $(PHONY) $(wildcard $^),$^)
define rule_cc_o_c
	./basic/fixdep $(depfile) $@ 'gcc $^ -o $@' > $(dot-target).tmp;  \
	mv -f $(dot-target).tmp $(dot-target).cmd
endef
if_changed_rule = $(if $(strip $(any-prereq) $(arg-check) ),        \
	@set -e;                                                        \
	$(rule_$(1)), @:)
$(TARGET): $(OBJS)
	$(call if_changed_rule,cc_o_c)
	gcc $^ -o $@
endif

ifeq ($(fixdep_method),3)
squote  := '
pound  := \#
escsq = $(subst $(squote),'\$(squote)',$1)
make-cmd = $(call escsq,$(subst $(pound),$$(pound),$(subst $$,$$$$,$(cmd_$(1)))))
cmd_cc_o_c = gcc -c $^ -o $@
define rule_cc_o_c
	./basic/fixdep $(depfile) $@ '$(call make-cmd,cc_o_c)' > \
	                                              $(dot-target).tmp; \
	mv -f $(dot-target).tmp $(dot-target).cmd
endef
$(TARGET): $(OBJS)
	$(call rule_cc_o_c)
	gcc $^ -o $@
endif

endif

.PHONY: clean  
clean:  
	rm -f $(OBJS) $(TARGET) $(DEPS) *.cmd
