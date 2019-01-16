# $Id: GNUmakefile,v 1.3 2004/01/07 16:43:52 marcel Exp $

include $(GNUSTEP_MAKEFILES)/common.make

LIBRARY_NAME = libMPWXmlKit

OBJCFLAGS += -Wno-import -fobjc-runtime=gnustep

LDFLAGS += -L /home/gnustep/Build/obj


libMPWXmlKit_HEADER_FILES = \
	MPWSaxProtocol.h		\
	MPWXmlAppleProplistGenerator.h	\
	MPWXmlAppleProplistReader.h	\
	MPWXmlArchiver.h		\
	MPWXmlAttribute.h		\
	MPWXmlAttributes.h		\
	MPWXmlCloseTag.h		\
	MPWXmlDOM.h			\
	MPWXmlDomParser.h		\
	MPWXmlElement.h			\
	MPWXmlEntityReference.h		\
	MPWXmlGeneratorStream.h		\
	MPWXmlParser.h			\
	MPWXmlParser16bit.h		\
	MPWXmlProplistGenerator.h	\
	MPWXmlSaxScanner.h		\
	MPWXmlScanner.h			\
	MPWXmlScanner16BitBE.h		\
	MPWXmlScanner16BitLE.h		\
	MPWXmlStartTag.h		\
	MPWXmlTag.h			\
	MPWXmlTag2ElementProcessor.h	\
	MPWXmlUnarchiver.h		\
	MPWXmlWrapperArchiver.h		\
	MPWXmlWrapperUnarchiver.h	\
	SaxDocumentHandler.h		\
	XmlCommonMacros.h		\
	XmlDelimitAttrValues.h		\
	XmlScannerPseudoMacro.h		\
	XmlScannerScanCDataPseudoMacro.h\

libMPWXmlKit_HEADER_FILES_DIR = .
libMPWXmlKit_HEADER_FILES_INSTALL_DIR = /MPWXmlKit

libMPWXmlKit_OBJC_FILES = \
    MPWXmlAppleProplistGenerator.m\
	MPWXmlArchiver.m  MPWXmlAttributes.m\
	MPWXmlGeneratorStream.m\
	MPWXmlParser.m \
	MPWXmlProplistGenerator.m MPWXmlSaxScanner.m\
	MPWXmlScanner.m \
	MPWXmlUnarchiver.m MPWXmlWrapperArchiver.m\
	MPWXmlWrapperUnarchiver.m\


libMPWXmlKit_LIBRARIES_DEPEND_UPON += \
	-lMPWFoundation -lgnustep-base -lobjc

libMPWXmlKit_INCLUDE_DIRS += -I. -I..   -I../MPWFoundation/.headers/
libMPWXmlKit_OBJCFLAGS += -Wno-import
libMPWXmlKit_CFLAGS += -Wno-import

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/library.make
-include GNUmakefile.postamble

