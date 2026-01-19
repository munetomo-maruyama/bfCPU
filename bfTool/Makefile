# Compiler and tools
#CC := x86_64-w64-mingw32-gcc
CC := gcc
FLEX := flex
BISON := bison
COPY := cp

# Target name
TARGET := bfTool
#TARGET_EXE := $(TARGET).exe
TARGET_EXE := $(TARGET)

# Directory structure
SRCDIR := src
OUTDIR := out
OBJDIR := $(OUTDIR)/obj
DEPDIR := $(OUTDIR)/dep
BINDIR := $(OUTDIR)/bin

# Compiler and linker options
CFLAGS := -I$(SRCDIR)
LDFLAGS := -static-libgcc -static-libstdc++
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$(*F).d

# Source files
SRC_C := $(wildcard $(SRCDIR)/*.c)
SRC_L := $(wildcard $(SRCDIR)/*.l)
SRC_Y := $(wildcard $(SRCDIR)/*.y)
LEX_C := $(SRC_L:$(SRCDIR)/%.l=$(SRCDIR)/%.lex.c)
TAB_C := $(SRC_Y:$(SRCDIR)/%.y=$(SRCDIR)/%.tab.c)
TAB_H := $(SRC_Y:$(SRCDIR)/%.y=$(SRCDIR)/%.tab.h)

# Object and dependency files
OBJ_C := $(addprefix $(OBJDIR)/, $(notdir $(SRC_C:.c=.o)))
OBJ_L := $(addprefix $(OBJDIR)/, $(notdir $(LEX_C:.lex.c=.lex.o)))
OBJ_Y := $(addprefix $(OBJDIR)/, $(notdir $(TAB_C:.tab.c=.tab.o)))
DEP_C := $(addprefix $(DEPDIR)/, $(notdir $(SRC_C:.c=.d)))
DEP_L := $(addprefix $(DEPDIR)/, $(notdir $(LEX_C:.lex.c=.lex.d)))
DEP_Y := $(addprefix $(DEPDIR)/, $(notdir $(TAB_C:.tab.c=.tab.d)))

# Default build rule
all: $(BINDIR)/$(TARGET_EXE)

# Flex rule: generate lexer source
$(SRCDIR)/%.lex.c: $(SRCDIR)/%.l
	$(FLEX) -o $@ $<

# Bison rule: generate parser source and header
$(SRCDIR)/%.tab.c $(SRCDIR)/%.tab.h: $(SRCDIR)/%.y
	$(BISON) -d -o $(SRCDIR)/$*.tab.c $<

# Compile lex generated source files into object files
$(OBJDIR)/%.lex.o: $(SRCDIR)/%.lex.c | $(OBJDIR) $(DEPDIR)
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<

# Compile yacc generated source files into object files
$(OBJDIR)/%.tab.o: $(SRCDIR)/%.tab.c | $(OBJDIR) $(DEPDIR)
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<

# Compile C source files into object files
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR) $(DEPDIR)
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<

# Link object files into final executable
$(BINDIR)/$(TARGET_EXE): $(OBJ_C) $(OBJ_L) $(OBJ_Y) | $(BINDIR)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^
	$(COPY) $(BINDIR)/$(TARGET_EXE) .

# Include generated lex and yacc files as sources
$(OBJ_C): $(LEX_C) $(TAB_C) $(TAB_H)

# Include dependency files if they exist
-include $(DEP_C) $(DEP_L) $(DEP_Y)

# Create necessary directories
$(OBJDIR) $(DEPDIR) $(BINDIR):
	@mkdir -p $@

# Empty rule to prevent errors if dependency files are missing
DEPS := $(DEP_C) $(DEP_L) $(DEP_Y)
$(DEPS):

# Clean up build artifacts
.PHONY: clean all
clean:
	@rm -rf $(LEX_C) $(TAB_C) $(TAB_H)
	@rm -rf $(OUTDIR)
