BEGIN {
    in_block_comment = 0
}
{
    line = $0
    output = ""
    in_string = 0
    escaped = 0
    i = 1
    while (i <= length(line)) {
        ch = substr(line, i, 1)
        next_ch = substr(line, i + 1, 1)

        if (in_block_comment) {
            if (ch == "*" && next_ch == "/") {
                in_block_comment = 0
                i += 2
                continue
            }
            i++
            continue
        }

        if (escaped) {
            output = output ch
            escaped = 0
            i++
            continue
        }

        if (ch == "\\" && in_string) {
            output = output ch
            escaped = 1
            i++
            continue
        }

        if (ch == "\"") {
            output = output ch
            in_string = !in_string
            i++
            continue
        }

        if (!in_string && ch == "/" && next_ch == "*") {
            in_block_comment = 1
            i += 2
            continue
        }

        if (!in_string && ch == "/" && next_ch == "/") {
            break
        }

        output = output ch
        i++
    }
    print output
}