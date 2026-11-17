* = $1001
        !word basic_end, 10
        !byte $9e
        !text "4109"
        !byte 0
basic_end
        !word 0

        ldx #0
print   lda message,x
        beq done
        jsr $ffd2
        inx
        bne print
done    jmp done

message !byte 147
        !text "HELLO WORLD"
        !byte 0
