# Compiler and tools
#CC := x86_64-w64-mingw32-gcc
CC := gcc
COPY := cp

# Target name
TARGET := bfRun
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
#LDFLAGS := -lgpiod -static-libgcc -static-libstdc++
LDFLAGS := -lm -lgpiod
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$(*F).d

# Source files
SRC_C := $(wildcard $(SRCDIR)/*.c)

# Object and dependency files
OBJ_C := $(addprefix $(OBJDIR)/, $(notdir $(SRC_C:.c=.o)))
DEP_C := $(addprefix $(DEPDIR)/, $(notdir $(SRC_C:.c=.d)))

# Default build rule
all: $(BINDIR)/$(TARGET_EXE)

# Compile C source files into object files
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR) $(DEPDIR)
	$(CC) $(DEPFLAGS) $(CFLAGS) -c -o $@ $<

# Link object files into final executable
$(BINDIR)/$(TARGET_EXE): $(OBJ_C) | $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	$(COPY) $(BINDIR)/$(TARGET_EXE) .

# Include generated lex and yacc files as sources
#$(OBJ_C): $(LEX_C) $(TAB_C) $(TAB_H)

# Include dependency files if they exist
-include $(DEP_C)

# Create necessary directories
$(OBJDIR) $(DEPDIR) $(BINDIR):
	@mkdir -p $@

# Empty rule to prevent errors if dependency files are missing
DEPS := $(DEP_C)
$(DEPS):

# Clean up build artifacts
.PHONY: clean all
clean:
	@rm -rf $(OUTDIR)
