#include <ruby.h>
#include <stdbool.h>
#include <limits.h>
#include "matrix.h"
#define RB_MATRIX(m) Data_Wrap_Struct( rb_cObject, NULL, Matrix_free, m )
#define GET_INFINITY rb_iv_get(self, "@inf")

inline Matrix * C_MATRIX(VALUE rm){
  Matrix * cm;
  Data_Get_Struct( rm, Matrix, cm );
  return cm;
}

void Floyd_iter(Matrix * length, Matrix * next){
  unsigned int k,i,j;
  for(k=0; k<length->size; k++){
    for(i=0; i<length->size; i++){
      if(Matrix_access(length, i, k) != -1){
        for(j=0; j<length->size; j++){
          if(Matrix_access(length, k, j) != -1){
            int new = Matrix_access(length, i, k) + Matrix_access(length, k, j);
            if(Matrix_access(length, i, j) == -1 || new < Matrix_access(length, i, j)){
              Matrix_set(length, i, j, new);
              Matrix_set(next, i, j, Matrix_access(next, i, k));
            }
          }
        }
      }
    }
  }
}

static unsigned int Tile_get_id(unsigned int size, VALUE pos){
  return NUM2INT(rb_ary_entry(pos, 0))*size + NUM2INT(rb_ary_entry(pos, 1));
}

static VALUE Tile_get_pos(unsigned int size, unsigned int id){
  return rb_ary_new3(2, INT2NUM(id / size), INT2NUM(id % size));
}

static int Floyd_Board_get_size(VALUE self){
  return NUM2INT(rb_iv_get(rb_iv_get(self, "@board"), "@size"));
}

static VALUE Floyd_initialize(VALUE self)
{
  rb_iv_set(self, "@next", Qnil);
  rb_iv_set(self, "@length", Qnil);
  rb_iv_set(self, "@board", Qnil);
  rb_iv_set(self, "@inf", rb_const_get(rb_const_get(rb_cObject, rb_intern("Float")), rb_intern("INFINITY")));
  return self;
}

static VALUE Floyd_compute(VALUE self)
{
  VALUE board = rb_iv_get(self, "@board");
  unsigned int size = NUM2INT(rb_iv_get(board, "@size"));
  unsigned int i,j;
  int to;
  Matrix * length = Matrix_create(size*size, -1);
  Matrix * next = Matrix_create(size*size, -1);
  for(i=0; i<size*size; i++){
    VALUE neighbour = rb_funcall(board, rb_intern("passable_neighbours"), 1, Tile_get_pos(size, i));
    for(j=0; j<RARRAY_LEN(neighbour); j++){
      to = Tile_get_id(size, rb_ary_entry(neighbour, j));
      Matrix_set(length, i, to, 1);
      Matrix_set(next, i, to, to);
    }
    Matrix_set(length, i, i, 0);
    Matrix_set(next, i, i, i);
  }
  Floyd_iter(length, next);
  rb_iv_set(self, "@next", RB_MATRIX(next));
  rb_iv_set(self, "@length", RB_MATRIX(length));
  return Qnil;
}

static VALUE Floyd_set_board(VALUE self, VALUE board)
{
  rb_iv_set(self, "@board", board);
  return Qnil;
}

static VALUE Floyd_search_path(VALUE self, VALUE from, VALUE to)
{
  VALUE path = rb_ary_new3(1, from);
  Matrix * next = C_MATRIX(rb_iv_get(self, "@next"));
  unsigned int size = Floyd_Board_get_size(self);
  int u = Tile_get_id(size, from), v = Tile_get_id(size, to);
  if(Matrix_access(next, u, v) == -1)
    return Qnil;

  while(u != v){
    u = Matrix_access(next, u, v);
    rb_ary_push(path, Tile_get_pos(size, u));
  }
  return path;
}

static VALUE Floyd_search_length(VALUE self, VALUE from, VALUE to)
{
  Matrix * length = C_MATRIX(rb_iv_get(self, "@length"));
  unsigned int size = Floyd_Board_get_size(self);
  int len = Matrix_access(length, Tile_get_id(size, from), Tile_get_id(size, to));
  return len == -1 ? GET_INFINITY : INT2NUM(len);
}

static VALUE Floyd_search_next(VALUE self, VALUE from, VALUE to)
{
  Matrix * next = C_MATRIX(rb_iv_get(self, "@next"));
  unsigned int size = Floyd_Board_get_size(self);
  int id = Matrix_access(next, Tile_get_id(size, from), Tile_get_id(size, to));
  return id == -1 ? Qnil : Tile_get_pos(size, id);
}

static VALUE Floyd_get_pos(VALUE self, VALUE id){
  return Tile_get_pos(Floyd_Board_get_size(self), NUM2INT(id));
}

static VALUE Floyd_get_id(VALUE self, VALUE pos){
  return INT2NUM(Tile_get_id(Floyd_Board_get_size(self), pos));
}

static VALUE Floyd_display_matrix(VALUE self){
  Matrix * length = C_MATRIX(rb_iv_get(self, "@length"));
  Matrix * next = C_MATRIX(rb_iv_get(self, "@next"));
  Matrix_display(next);
  puts("");
  Matrix_display(length);
  return Qnil;
}

void Init_floyd()
{
  // Define a new module
  VALUE Pathfinding = rb_define_module("Pathfinding");
  // Define a new class (inheriting Object) in this module
  VALUE Floyd = rb_define_class_under(Pathfinding, "Floyd", rb_cObject);
  rb_define_method(Floyd, "initialize", Floyd_initialize, 0);
  rb_define_method(Floyd, "compute", Floyd_compute, 0);
  rb_define_method(Floyd, "search_path", Floyd_search_path, 2);
  rb_define_method(Floyd, "search_length", Floyd_search_length, 2);
  rb_define_method(Floyd, "search_next", Floyd_search_next, 2);
  rb_define_method(Floyd, "board=", Floyd_set_board, 1);
  rb_define_method(Floyd, "get_pos", Floyd_get_pos, 1);
  rb_define_method(Floyd, "get_id", Floyd_get_id, 1);
  rb_define_method(Floyd, "display_matrix", Floyd_display_matrix, 0);
}
