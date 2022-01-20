import random
import argparse

def build_word_map(file_to_read_path):
    '''
    Builds a word map from a file path.
    '''
    word_map = {}
    with open(file_to_read_path, 'r', encoding='utf-8') as f:
        for line in f:
            if '{' in line:
                word_map = {}
            if '#' in line:
                word = line[line.rfind('#')+1:].strip()
                word_map[word] = []
            if "|" in line:
                test_list = [test.strip().replace('-', word) if '-' in test.strip() else test.strip() for test in line.split('|') if len(test.strip()) > 0]
                test_list
                word_map[word].extend(test_list)
            if '}' in line:
                break

    for word, test_list in word_map.items():
        if len(test_list) == 0:
            test_list.append(word)

    return word_map


def build_line_to_write_list(file_to_read_path, word_map):
    '''
    Builds a list of lines to write to the file from a word map built.
    '''
    line_to_write_list = []
    for word, test_list in word_map.items():
        for test in test_list:
            line_to_write = f'[[{file_to_read_path}#{word}|{test}]]\n'
            line_to_write_list.append(line_to_write)
    
    return line_to_write_list

def write_lines(file_to_write_path, line_to_write_list):
    '''
    Writes lines to a file opened.
    '''
    with open(file_to_write_path, 'w', encoding='utf-8') as f:
        for line in line_to_write_list:
            f.write(line)

def main():
    parser = argparse.ArgumentParser(description="A script to build up a test from one markdown note in Obsdian.")

    parser.add_argument('-i', '--input', help='Path of input, which should be your word note (markdown), default is word_note.md.', required=False, default='word_note.md')
    parser.add_argument('-o', '--output', help='Path of output, which should be the generated test name (markdown), default is word_test.md.', required=False, default='word_test.md')
    parser.add_argument('-s', '--shuffle', help='Turn on shuffle, default is True.', required=False, default=True)

    args = parser.parse_args()

    word_map = build_word_map(args.input)
    line_to_write_list = build_line_to_write_list(args.input, word_map)
    if args.shuffle:
        random.shuffle(line_to_write_list)
    write_lines(args.output, line_to_write_list)




if __name__ == '__main__':
    main()
