include ../../config

OCAMLFLAGS += -I ../../lib
OCAMLOPTFLAGS += -I ../../lib
ZLEXTRALIBS = $(ZLGTKLIBS)

SRC = trace.zls combinators.zls

default: $(word 1, $(targets))
all:  $(targets)
byte: $(SRC:.zls=.byte)
opt: $(SRC:.zls=.opt)

$(SRC:.zls=.byte):
	$(MAKE) $(@:.byte=.ml) $(@:.byte=_main.ml)
	$(OCAMLC) $(OCAMLFLAGS) -o $@ \
	    $(ZLSTDLIBS) $(ZLEXTRALIBS) $(INCLUDES) $(@:.byte=.ml) $(@:.byte=_main.ml)

$(SRC:.zls=.opt):
	$(MAKE) $(@:.opt=.ml) $(@:.opt=_main.ml)
	$(OCAMLOPT) $(OCAMLOPTFLAGS) -o $@ \
	    $(ZLSTDLIBS:.cma=.cmxa) $(ZLEXTRALIBS:.cma=.cmxa) \
			$(INCLUDES:.cma=.cmxa) $(@:.opt=.ml) $(@:.opt=_main.ml)

$(SRC:.zls=.ml):
	$(ZELUC) $(ZELUCFLAGS) $(ZELUCEXTRAFLAGS) -gtk2 -s main -o $(@:.ml=_main) $(@:.ml=.zls)

clean:
	@rm -f $(SRC:.zls=.zci) $(SRC:.zls=.ml) $(SRC:.zls=_main.ml)
	@rm -f $(SRC:.zls=.cmo) $(SRC:.zls=.cmx) $(SRC:.zls=.cmi)
	@rm -f $(SRC:.zls=_main.cmo) $(SRC:.zls=_main.cmx) $(SRC:.zls=_main.cmi)
	@rm -f $(SRC:.zls=.annot) $(SRC:.zls=_main.annot)
	@rm -f $(SRC:.zls=.o) $(SRC:.zls=_main.o)

realclean cleanall: clean
	@rm -f $(SRC:.zls=.byte) $(SRC:.zls=.opt)
