#instruction format is [instruction] [condition] [register] [register]* [register]*
#*some instructions only use two instructions, in which case the last two registers are filled with 0's
#for branch functions, the format is [instruction] [condition] [label]

conditions = {
    'EQ': '0000',
    'NE': '0001',
    'CS': '0010',
    'CC': '0011',
    'MI': '0100',
    'PL': '0101',
    'VS': '0110',
    'VC': '0111',
    'HI': '1000',
    'LS': '1001',
    'GE': '1010',
    'LT': '1011',
    'GT': '1100',
    'LE': '1101',
    'AL': '1110'
}

DPFunctions = {
    'ADD': '0000',
    'SUB': '0001',
    'AND': '0010',
    'ORR': '0011',
    'EOR': '0100',
    'MVN': '0101',
    'CMP': '0110',
    'LSL': '0111',
    'LSR': '1000',
    'ASR': '1001',
    'ROR': '1010',
    'MOV': '1011',
    'ADDS': '1100',
    'SUBS': '1101',
    'CSP': '1110',
    'CPO': '1111'
}

registers = {
    'R0': '000',
    'R1': '001',
    'R2': '010',
    'R3': '011',
    'R4': '100',
    'R5': '101',
    'R6': '110',
    'R7': '111'
}

memFunctions = {
    'LDR': '0',
    'STR': '1'
}

branchFunctions = {
    'B': '0',
    'BL': '1'
}

specialFunctions = {
    'HALT': '00',
    'NOP': '01',
    'PUSH': '10',
    'POP': '11'
}

labels = dict()
branchLabels = dict()
instrAddress = 0
assembled = []

def assemble(x: str):
    global instrAddress
    global assembled
    global labels
    x = x.split()
    register = ['000'] * 3
    opcode = '00'
    if x[0] in DPFunctions:
        condition = conditions[x[1]]
        opcode = '00'
        register[0] = registers[x[2]]
        if x[0] not in ('CPO', 'CSP'):
            register[1] = registers[x[3]]

        ml = condition + opcode + DPFunctions[x[0]] + register[0] + register[1]
        assembled.append(ml)

    elif x[0] in memFunctions:
        condition = conditions[x[1]]
        opcode = '01'
        register = [registers[x[2]], registers[x[3]], registers[x[4]]]

        ml = condition + opcode + memFunctions[x[0]] + register[0] + register[1] + register[2]
        assembled.append(ml)

    elif x[0] in specialFunctions:
        condition = conditions[x[1]]
        opcode = '11'
        if x[0] in ('POP', 'PUSH'):
            register[0] = registers[x[2]]

        ml = condition + opcode + specialFunctions[x[0]] + '11' + register[0] + '111'
        assembled.append(ml)

    elif x[0] in branchFunctions:
        condition = conditions[x[1]]
        opcode = '10'
        if x[2] in labels:
            offset = instrAddress - labels[x[2]] + 1
            if offset > 255 or offset < -256:
                raise ValueError("Branch function too far away to jump to.")
            if offset >= 0:
                offset = bin(offset)[2:].zfill(9)
            else:
                offset = bin(offset)[3:].zfill(9)
                offset = ''.join(['1' if offset[i] == '0' else '0' for i in range(9)])
                offset = bin(int(offset, 2) + 1)[2:]

            ml = condition + opcode + branchFunctions[x[0]] + offset
            assembled.append(ml)
        else:
            if x[2] in branchLabels:
                branchLabels[x[2]].append(instrAddress)
            else:
                branchLabels[x[2]] = [instrAddress]

            ml = condition + opcode + branchFunctions[x[0]]
            assembled.append(ml)

    else:
        if x[0] in branchLabels:
            for i in range(len(branchLabels[x[0]])):
                offset = branchLabels[x[0]][i] - instrAddress + 1
                if offset > 255 or offset < -256:
                    raise ValueError("Branch function too far away to jump to.")
                if offset >= 0:
                    offset = bin(offset)[2:].zfill(9)
                else:
                    offset = bin(offset)[3:].zfill(9)
                    offset = ''.join(['1' if offset[i] == '0' else '0' for i in range(9)])
                    offset = bin(int(offset, 2) + 1)[2:]
                assembled[branchLabels[x[0]][i]] += offset
        if x[0] in labels:
            raise ValueError('Branch name already used.')
        labels[x[0]] = instrAddress

        ml = '1110110100000000' #NOP for branch headers
        assembled.append(ml)

    instrAddress += 1

with open('program.txt', 'r', encoding='utf-8') as file:
    for line in file:
        if line.strip() == '' or line.strip()[:2] == '//':
            continue
        assemble(line)

with open('assembled.txt', 'w', encoding='utf-8') as writefile:
    for line in assembled:
        print(line, file=writefile)
             