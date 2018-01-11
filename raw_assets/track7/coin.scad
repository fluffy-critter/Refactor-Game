scale(32/24) for (i=[0:7]) rotate([0,i*180/8 - 90,0]) translate([0,-24*i - 12,-1]) {
    difference() {
        cylinder(r=10,h=2);
        translate([0,0,1.5]) cylinder(r1=8, r2=10, h=0.6);
    }

    union() {
        rotate_extrude($fn=24) translate([3.5,.8,0]) circle(r=1,$fn=12);
        translate([0,0,0.75]) rotate([90,0,45]) union() {
            linear_extrude(height=10,center=true) circle(r=1,$fn=12);
            translate([0,0,5]) sphere(r=1,$fn=12);
            translate([0,0,-5]) sphere(r=1,$fn=12);
        }
    }
}