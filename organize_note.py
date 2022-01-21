import random
import argparse

def build_word_map(file_to_read_path):
    '''
    Builds a word map from a file path.
    '''
    word_map = {}
    recording_word = None
    with open(file_to_read_path, 'r', encoding='utf-8') as f:
        slicing = False
        selected = True
        for line in f:
            if '{' in line:
                if not slicing:
                    recording_word = None
                    word_map = {}
                    slicing = True
                selected = True
            if '}' in line and slicing:
                recording_word = None
                selected = False

            if '#' in line and selected:
                recording_word = line[line.rfind('#')+1:].strip().strip('{').strip('}')
            elif recording_word is not None and selected:
                word_map.setdefault(recording_word, []).append(line.strip().strip('{').strip('}'))
                
    return word_map

def build_line_to_write_list(word_map, shuffle, to_sort, emphasis, mark):
    '''
    Builds a list of lines to write to the file from a word map built.
    '''
    title_list = list(word_map.keys())

    if shuffle:
        random.shuffle(title_list)
    if to_sort:
        title_list.sort()
    
    line_to_write_list = []

    index = 1
    for title in title_list:
        if mark:
            line_to_write_list.append(f'{"#"*emphasis} {index}. {title}\n')
        else:
            line_to_write_list.append(f'{"#"*emphasis} {title}\n')
        index += 1
            
        for text in word_map[title]:
            line_to_write_list.append(f'{text}\n')

    return line_to_write_list

def write_lines(file_to_write_path, line_to_write_list):
    '''
    Writes lines to a file opened.
    '''
    with open(file_to_write_path, 'w', encoding='utf-8') as f:
        index = 1
        for line in line_to_write_list:
            line = f'{line}'
            index += 1
            f.write(line)

def main():
    parser = argparse.ArgumentParser(description="A script to build up one newly organized note from one markdown note in Obsdian.")

    parser.add_argument('-i', '--input', help='path of input, which should be your word note (markdown), default is word_note.md.', \
        type=str, required=False, default='word_note.md')
    parser.add_argument('-o', '--output', help='path of output, which should be the generated new note name (markdown), default is word_organized.md.', \
        type=str, required=False, default='word_organized.md')
    parser.add_argument('-e', '--emphasis', help='to set the one word into different level of level to emphasize, default is 4, 0 is to turn off.', \
        type=int, required=False, default=4)

    parser.add_argument('-s', '--shuffle', help='turn on shuffle.', required=False, action='store_true')
    parser.add_argument('-m', '--mark', help='to mark a number of each test.', required=False, action='store_true')
    parser.add_argument('-t', '--sort', help='sort the test. This will disable shuffle!', required=False, action='store_true')
    parser.add_argument('--overwrite', help='**WARNING** this will overwrite the original input file. This will disable output parameter!', required=False, action='store_true')

    args = parser.parse_args()

    if args.overwrite:
        args.output = args.input
    
    word_map = build_word_map(args.input)
    line_to_write_list = build_line_to_write_list(word_map, args.shuffle, args.sort, args.emphasis, args.mark)
    write_lines(args.output, line_to_write_list)


if __name__ == '__main__':
    main()