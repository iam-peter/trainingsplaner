#include "ket.h"

#include "youth.h"

namespace Ket {

namespace {

// One weight class: its upper limit, negative for the "+" class above it,
// and the totals by age from the level's first age on, 0 where the class
// doesn't exist for that age (the youth's up to 17, the adults' from 18).
// Taken from the four PDFs "Normsystem BVDG_2026, Stand 26.01.2026".
struct Row
{
    int limit;
    int totals[10];
};

const Row nk1Men[] = {
    {  55, {166, 179, 193,   0,   0,   0,   0,   0,   0,   0}},
    {  60, {180, 194, 208, 219, 230, 238, 243, 246, 249, 252}},
    {  65, {192, 207, 223, 234, 245, 254, 260, 263, 266, 269}},
    {  70, {203, 219, 235, 247, 259, 268, 274, 278, 281, 285}},
    {  75, {212, 229, 246, 259, 271, 281, 287, 291, 294, 298}},
    {  85, {228, 246, 264, 277, 291, 301, 308, 312, 316, 320}},
    {  95, {239, 258, 277, 291, 305, 316, 324, 328, 332, 336}},
    { -95, {251, 271, 291,   0,   0,   0,   0,   0,   0,   0}},
    { 110, {  0,   0,   0, 306, 320, 332, 339, 344, 348, 352}},
    {-110, {  0,   0,   0, 310, 325, 337, 345, 349, 353, 358}},
};

const Row nk1Women[] = {
    {  45, {120, 125, 130,   0,   0,   0,   0,   0,   0,   0}},
    {  49, {129, 135, 141, 146, 151, 156, 159, 161, 164, 166}},
    {  53, {138, 144, 150, 156, 161, 166, 169, 172, 175, 177}},
    {  57, {146, 152, 158, 164, 170, 175, 179, 181, 184, 187}},
    {  61, {151, 157, 164, 170, 176, 181, 185, 188, 191, 193}},
    {  69, {160, 167, 174, 180, 186, 192, 196, 199, 202, 205}},
    {  77, {165, 173, 180, 186, 193, 199, 203, 206, 209, 212}},
    { -77, {169, 177, 184,   0,   0,   0,   0,   0,   0,   0}},
    {  86, {  0,   0,   0, 191, 198, 203, 208, 211, 214, 217}},
    { -86, {  0,   0,   0, 194, 201, 207, 211, 214, 218, 221}},
};

const Row pkMen[] = {
    {  60, {248, 258, 261, 265, 268, 271, 275, 278, 281, 284}},
    {  65, {263, 276, 279, 283, 286, 290, 293, 297, 300, 304}},
    {  70, {278, 291, 295, 299, 303, 306, 310, 314, 317, 321}},
    {  75, {292, 305, 309, 313, 317, 321, 325, 329, 332, 336}},
    {  85, {313, 328, 332, 336, 340, 344, 348, 352, 356, 360}},
    {  95, {329, 344, 348, 352, 357, 361, 365, 370, 374, 379}},
    { 110, {345, 360, 365, 370, 374, 379, 383, 388, 393, 397}},
    {-110, {350, 366, 371, 375, 380, 385, 389, 394, 399, 403}},
};

const Row pkWomen[] = {
    {  49, {162, 168, 171, 173, 176, 178, 181, 184, 186, 189}},
    {  53, {173, 179, 182, 185, 188, 191, 193, 196, 199, 202}},
    {  57, {183, 189, 192, 195, 198, 201, 204, 207, 210, 213}},
    {  61, {189, 196, 199, 202, 205, 208, 211, 214, 217, 220}},
    {  69, {201, 208, 211, 214, 217, 221, 224, 227, 230, 234}},
    {  77, {208, 215, 218, 222, 225, 229, 232, 235, 239, 242}},
    {  86, {213, 220, 224, 227, 230, 234, 237, 241, 244, 248}},
    { -86, {217, 224, 228, 231, 235, 238, 241, 245, 248, 251}},
};

template <size_t N>
int lookup(const Row (&rows)[N], int limit, int index)
{
    for (const Row &r : rows) {
        if (r.limit == limit)
            return r.totals[index];
    }
    return 0;
}

} // namespace

int firstAge(Level level)
{
    return level == NK1 ? 15 : 19;
}

int lastAge(Level level)
{
    return firstAge(level) + 9;
}

QString name(Level level)
{
    return level == NK1 ? QStringLiteral("KET 2026 NK1 (15–24)") : QStringLiteral("KET 2026 PK (19–28)");
}

int norm(Level level, Sex sex, int age, double bodyWeight)
{
    if (bodyWeight <= 0 || age < firstAge(level) || age > lastAge(level))
        return 0;
    // The lightest class the body weight fits, else the "+" class
    const QList<int> limits = Youth::weightClassLimits(int(sex), age);
    int limit = -limits.last();
    for (int l : limits) {
        if (bodyWeight <= l) {
            limit = l;
            break;
        }
    }
    const int index = age - firstAge(level);
    if (level == NK1)
        return sex == Sex::Female ? lookup(nk1Women, limit, index) : lookup(nk1Men, limit, index);
    return sex == Sex::Female ? lookup(pkWomen, limit, index) : lookup(pkMen, limit, index);
}

} // namespace Ket
