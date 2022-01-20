import random
import argparse
from xmlrpc.client import boolean



def detect_contain_chinese(strs):
    '''
    Detect if a string contains chinese.
    '''
    for ch in strs:
        if '\u4e00' <= ch <= '\u9fff':
            return True
    return False


def detect_contain_japanese(strs):
    '''
    Detect if a string contains japanese.
    '''
    for ch in strs:
        if '\u3040' <= ch <= '\u30ff':
            return True
    return False


def detect_all_english(strs):
    '''
    Detect if a string contains all english.
    '''
    try:
        strs.encode(encoding='utf-8').decode('ascii')
    except UnicodeDecodeError:
        return False
    else:
        return True


def build_word_map(file_to_read_path):
    '''
    Builds a word map from a file path.
    '''
    word_map = {}
    with open(file_to_read_path, 'r', encoding='utf-8') as f:
        slicing = False
        selected = True
        for line in f:
            if '{' in line:
                if not slicing:
                    word_map = {}
                    slicing = True
                selected = True
            if '#' in line and selected:
                word = line[line.rfind('#')+1:].strip()
                word_map[word] = []
            if "|" in line and selected:
                test_list = [test.strip().replace('-', word) if '-' in test.strip() else test.strip() for test in line.split('|') if len(test.strip()) > 0]
                test_list
                word_map[word].extend(test_list)
            if '}' in line and slicing:
                selected = False

    for word, test_list in word_map.items():
        if len(test_list) == 0:
            test_list.append(word)

    return word_map


def build_line_to_write_list(file_to_read_path, word_map, shuffle, to_sort, exclude_chinese, exclude_japanese, exclude_english):
    '''
    Builds a list of lines to write to the file from a word map built.
    '''
    line_to_write_list = []
    for word, test_list in word_map.items():
        for test in test_list:
            if (exclude_chinese and detect_contain_chinese(test)) or \
                (exclude_japanese and detect_contain_japanese(test)) or \
                (exclude_english and detect_all_english(test)):
                continue

            line_to_write = f'[[{file_to_read_path}#{word}|{test}]]\n'
            line_to_write_list.append(line_to_write)

    if shuffle:
        random.shuffle(line_to_write_list)
    if to_sort:
        line_to_write_list.sort()
    
    return line_to_write_list


def write_lines(file_to_write_path, line_to_write_list, emphasis, mark):
    '''
    Writes lines to a file opened.
    '''
    with open(file_to_write_path, 'w', encoding='utf-8') as f:
        index = 1
        for line in line_to_write_list:
            if mark:
                line = f'{"#" * emphasis} {index}. {line}'
                index += 1
            f.write(line)

def main():
    parser = argparse.ArgumentParser(description="A script to build up a test from one markdown note in Obsdian.")

    parser.add_argument('-i', '--input', help='path of input, which should be your word note (markdown), default is word_note.md.', \
        type=str, required=False, default='word_note.md')
    parser.add_argument('-o', '--output', help='path of output, which should be the generated test name (markdown), default is word_test.md.', \
        type=str, required=False, default='word_test.md')
    parser.add_argument('-s', '--shuffle', help='turn on shuffle, default is True.', type=bool, required=False, default=True)
    parser.add_argument('-e', '--emphasis', help='to set the one word into different level of level to emphasize, default is 3, 0 is to turn off.', \
        type=int, required=False, default=4)
    parser.add_argument('-m', '--mark', help='to mark a number of each test, default is True.', type=bool, required=False, default=True)
    parser.add_argument('-t', '--sort', help='sort the test, default is False. This will disable shuffle!', type=bool, required=False, default=False)
    parser.add_argument('--exchinese', help='exclude items containing Chinese, default is False.', type=bool, required=False, default=False)
    parser.add_argument('--exjapanese', help='exclude items containing Japanese, default is False.', type=bool, required=False, default=False)
    parser.add_argument('--exenglish', help='exclude items which is *ALL* English, default is False.', type=bool, required=False, default=False)

    args = parser.parse_args()

    word_map = build_word_map(args.input)
    line_to_write_list = build_line_to_write_list(args.input, word_map, args.shuffle, args.sort, args.exchinese, args.exjapanese, args.exenglish)
    write_lines(args.output, line_to_write_list, args.emphasis, args.mark)



if __name__ == '__main__':
    main()
