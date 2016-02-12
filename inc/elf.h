#ifndef JOS_INC_ELF_H
#define JOS_INC_ELF_H

#define ELF_MAGIC 0x464C457FU	/* "\x7FELF" in little endian */

struct Elf {
	uint32_t e_magic;	// must equal ELF_MAGIC
	uint8_t e_elf[12];
	uint16_t e_type;       // 目标文件类型
	uint16_t e_machine;    // 硬件平台
	uint32_t e_version;    // elf头部版本
	uint32_t e_entry;      // 程序入口点
	uint32_t e_phoff;      // 程序头表偏移量
	uint32_t e_shoff;      // 节头表偏移量
	uint32_t e_flags;      // 处理器特定标志
	uint16_t e_ehsize;     // elf头部长度
	uint16_t e_phentsize;  // 程序头表中一个条目的长度
	uint16_t e_phnum;      // 程序头表条目数目
	uint16_t e_shentsize;  // 节头表中一个条目的长度
	uint16_t e_shnum;      // 节头表条目数目
	uint16_t e_shstrndx;   // 节头表字符索引
};

struct Proghdr {
	uint32_t p_type;    // 段类型
	uint32_t p_offset;  // 段的位置相对于文件开始处的偏移
	uint32_t p_va; 	    // 段在内存中的首字节地址（虚拟地址？）
	uint32_t p_pa; 	    // 段的物理地址
	uint32_t p_filesz;  // 段在文件映像中的字节数
  	uint32_t p_memsz;   // 段在内存映像中的字节数
 	uint32_t p_flags;   // 段标记
	uint32_t p_align;   // 段在内存中的对齐标记
};

struct Secthdr {
	uint32_t sh_name;   // 小节名在字符表中的索引
	uint32_t sh_type;   // 小节的类型
	uint32_t sh_flags;  // 小节属性
	uint32_t sh_addr;   // 小节在运行时的虚拟地址
	uint32_t sh_offset; // 小节的文件偏移
	uint32_t sh_size;   // 小节的大小（以字节为单位）
	uint32_t sh_link;   // 链接的另外一小节的索引
	uint32_t sh_info;   // 附加的小节信息
	uint32_t sh_addralign; // 小节对齐
	uint32_t sh_entsize; // 一些sectors保存着一张固定大小入口的表
};

// Values for Proghdr::p_type
#define ELF_PROG_LOAD		1

// Flag bits for Proghdr::p_flags
#define ELF_PROG_FLAG_EXEC	1
#define ELF_PROG_FLAG_WRITE	2
#define ELF_PROG_FLAG_READ	4

// Values for Secthdr::sh_type
#define ELF_SHT_NULL		0
#define ELF_SHT_PROGBITS	1
#define ELF_SHT_SYMTAB		2
#define ELF_SHT_STRTAB		3

// Values for Secthdr::sh_name
#define ELF_SHN_UNDEF		0

#endif /* !JOS_INC_ELF_H */
