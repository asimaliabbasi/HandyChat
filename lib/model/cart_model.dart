import 'package:flutter/cupertino.dart';

class CartModel extends ChangeNotifier {
  // list of item on sale
  final List _shopItems = [
    ["Alphabet a", "A", "assets/images/a_small.gif"],
    ["Alphabet b", "B", "assets/images/b_small.gif"],
    ["Alphabet c", "C", "assets/images/c_small.gif"],
    ["Alphabet d", "D", "assets/images/d_small.gif"],
    ["Alphabet e", "E", "assets/images/e_small.gif"],
    ["Alphabet f", "F", "assets/images/f_small.gif"],
    ["Alphabet g", "G", "assets/images/g_small.gif"],
    ["Alphabet h", "H", "assets/images/h_small.gif"],
    ["Alphabet i", "I", "assets/images/i_small.gif"],
    ["Alphabet j", "J", "assets/images/j_small.gif"],
    ["Alphabet k", "K", "assets/images/k_small.gif"],
    ["Alphabet l", "L", "assets/images/l_small.gif"],
    ["Alphabet m", "M", "assets/images/m_small.gif"],
    ["Alphabet n", "N", "assets/images/n_small.gif"],
    ["Alphabet o", "O", "assets/images/o_small.gif"],
    ["Alphabet p", "P", "assets/images/p_small.gif"],
    ["Alphabet q", "Q", "assets/images/q_small.gif"],
    ["Alphabet r", "R", "assets/images/r_small.gif"],
    ["Alphabet s", "S", "assets/images/s_small.gif"],
    ["Alphabet t", "T", "assets/images/t_small.gif"],
    ["Alphabet u", "U", "assets/images/u_small.gif"],
    ["Alphabet v", "V", "assets/images/v_small.gif"],
    ["Alphabet w", "W", "assets/images/w_small.gif"],
    ["Alphabet x", "X", "assets/images/x_small.gif"],
    ["Alphabet y", "Y", "assets/images/y_small.gif"],
    ["Alphabet z", "Z", "assets/images/z_small.gif"],


  ];
  get shopItems => _shopItems;
}
