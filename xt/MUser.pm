# -------------------- this does NOT work --------------------
package # hide from PAUSE indexer
 MUser;
        use parent 'DbUser';
        use parent 'Class::Accessor::Fast'; # NEEDED!?
        has hotstuff => (is => 'rw', isa => "Str");
        __PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
